#!/bin/bash
# Audit gate: every package the runtime-closure analysis below flags as purgable
# must be classified in build/keep-packages.txt, build/purge-packages.txt, or
# build/purge-packages-late.txt; otherwise the build fails here. This is how the
# purge lists are maintained -- empty them and let the errors name what to
# triage, the same try-and-error loop as build/essential-packages.txt.
#
# It runs on the BUILD HOST during the mmdebstrap customize-hook, before the
# purge hooks, with $1 = the pre-purge rootfs. It only READS that rootfs
# (readelf / dpkg-query --admindir / ldconfig -C) and downloads the extra
# browsers outside it, so the runtime image is never touched.
#
# The closure follows DT_NEEDED links, so keep-packages.txt must cover what it
# cannot see: data read via fontconfig/icon/mime caches, Essentials used without
# being declared, dlopen (mesa, libsystemd-shared, firefox's libcloudproviders0)
# and exec (chrome's sandbox walking /proc via ps).
set -u
export LC_ALL=C

ROOTFS="${1:?usage: audit.sh <rootfs>}"
# The package lists are this script's siblings; the browser installer and the
# target architecture come from the rootfs under audit, so nothing here depends
# on the Dockerfile's build-time paths.
BUILD="$(cd -- "$(dirname -- "$0")" && pwd)"
BROWSERS="$ROOTFS/opt/vivliostyle-cli/node_modules/.bin/browsers"

dq()    { dpkg-query --admindir="$ROOTFS/var/lib/dpkg" "$@"; }
strip() { sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$1"; }
# usrmerge: ld.so.cache stores /lib paths but dpkg records the /usr-merged form.
canon() { case "$1" in /lib/*|/bin/*|/sbin/*|/lib32/*|/lib64/*|/libx32/*) printf '/usr%s' "$1";; *) printf '%s' "$1";; esac; }

arch=$(dq -W --showformat='${Architecture}\n' dpkg | head -n1)

# ---- contract browsers (read-only, downloaded outside the rootfs) ---------
# image-contract.sh installs chrome / chromium / firefox in derived images, so
# the slim image must keep their shared-library packages. The bundle ships one;
# download the others to a throwaway host directory only to read their NEEDED
# entries below. Nothing here is written into $ROOTFS.
dl=$(mktemp -d)
trap 'rm -rf "$dl"' EXIT
"$BROWSERS" install firefox --path "$dl" >/dev/null 2>&1 \
    || { echo "audit: could not download firefox for closure analysis" >&2; exit 1; }
if [ "$arch" = amd64 ]; then
    "$BROWSERS" install chromium --path "$dl" >/dev/null 2>&1 \
        || { echo "audit: could not download chromium for closure analysis" >&2; exit 1; }
fi

# ---- seeds ----------------------------------------------------------------
# Everything image-contract.sh exercises at runtime. Rootfs files are read at
# their $ROOTFS-prefixed host path; the extra browsers live under $dl.
seeds=()
add() { for f in "$@"; do [ -e "$f" ] && seeds+=("$f"); done; }
add "$ROOTFS"/usr/bin/node "$ROOTFS"/usr/bin/npm "$ROOTFS"/usr/bin/pnpm "$ROOTFS"/usr/bin/pnpx
add "$ROOTFS"/usr/bin/chromium
for f in "$ROOTFS"/opt/puppeteer/chrome/*/chrome-linux*/chrome \
         "$ROOTFS"/opt/puppeteer/chrome/*/chrome-linux*/chrome-sandbox \
         "$ROOTFS"/opt/puppeteer/chrome/*/chrome-linux*/chrome_crashpad_handler \
         "$dl"/chromium/*/chrome-linux/chrome \
         "$dl"/chromium/*/chrome-linux/chrome-sandbox \
         "$dl"/firefox/*/firefox/firefox \
         "$dl"/firefox/*/firefox/firefox-bin; do
    add "$f"
done
# firefox routes work through libxul + $ORIGIN-relative helpers; chromium's
# swiftshader / vulkan .so sit next to chrome. Seed every .so in those dirs.
for d in "$dl"/firefox/*/firefox "$dl"/chromium/*/chrome-linux; do
    [ -d "$d" ] || continue
    for so in "$d"/*.so; do add "$so"; done
done
add "$ROOTFS"/usr/bin/gs "$ROOTFS"/usr/bin/pdftops "$ROOTFS"/usr/bin/pdfinfo
add "$ROOTFS"/usr/bin/fc-list "$ROOTFS"/usr/bin/fc-match "$ROOTFS"/usr/bin/fc-cache "$ROOTFS"/usr/bin/fc-query
add "$ROOTFS"/usr/bin/unzip "$ROOTFS"/usr/bin/xz "$ROOTFS"/usr/bin/tar
add "$ROOTFS"/usr/bin/apt "$ROOTFS"/usr/bin/apt-get "$ROOTFS"/usr/bin/apt-cache \
    "$ROOTFS"/usr/bin/dpkg "$ROOTFS"/usr/bin/dpkg-deb "$ROOTFS"/usr/bin/dpkg-query
add "$ROOTFS"/usr/local/bin/vivliostyle "$ROOTFS"/usr/local/bin/vs
add "$ROOTFS"/opt/vivliostyle-cli/node_modules/.bin/press-ready

# ---- shared-library closure (readelf + the rootfs ld.so.cache) ------------
# The slim rootfs has no bash, so its ldd (a bash script) cannot run there;
# resolve DT_NEEDED with readelf and the rootfs cache instead. This yields the
# same package set as a recursive ldd.
declare -A SOPATH
while IFS= read -r line; do
    case "$line" in
        *' => '*) sn=${line#$'\t'}; sn=${sn%% *}
                  [ -n "${SOPATH[$sn]:-}" ] || SOPATH[$sn]=$(canon "${line##* => }") ;;
    esac
done < <(ldconfig -C "$ROOTFS/etc/ld.so.cache" -p 2>/dev/null)

declare -A SEEN
queue=("${seeds[@]}")
while [ ${#queue[@]} -gt 0 ]; do
    f=${queue[0]}; queue=("${queue[@]:1}")
    [ -n "${SEEN[$f]:-}" ] && continue
    SEEN[$f]=1
    [ -e "$f" ] || continue
    while IFS= read -r sn; do
        p=${SOPATH[$sn]:-}
        [ -n "$p" ] && queue+=("$ROOTFS$p")
    done < <(readelf -d "$f" 2>/dev/null | sed -n 's/.*(NEEDED).*\[\(.*\)\].*/\1/p')
done

# Map every visited rootfs file to its owning package.
closure=$(for f in "${!SEEN[@]}"; do
    case "$f" in "$ROOTFS"/*) dq -S "${f#"$ROOTFS"}" 2>/dev/null | cut -d: -f1;; esac
done | tr ',' '\n' | sed 's/[[:space:]]//g;/^$/d' | sort -u)

# ---- declared-dependency closure ------------------------------------------
# Walk Depends + Pre-Depends from the linked closure, resolving Provides so
# virtual names match the real package. Catches keepers the linker misses:
# helpers spawned via exec, daemons we depend on but do not link.
declare -A REAL
while IFS= read -r line; do
    pkg=${line%%$'\t'*}; prov=${line#*$'\t'}
    [ -n "$pkg" ] || continue
    REAL[$pkg]=$pkg
    [ -n "$prov" ] || continue
    while IFS= read -r v; do
        [ -n "$v" ] && [ -z "${REAL[$v]:-}" ] && REAL[$v]=$pkg
    done < <(printf '%s' "$prov" | sed 's/([^)]*)//g' | tr ',' '\n' | sed 's/[[:space:]]//g;/^$/d')
done < <(dq -W --showformat='${Package}\t${Provides}\n' 2>/dev/null)

declare -A VISITED
depqueue=()
while IFS= read -r p; do [ -n "$p" ] && depqueue+=("$p"); done <<<"$closure"
depqueue+=(apt dpkg ca-certificates)
i=0
while [ "$i" -lt "${#depqueue[@]}" ]; do
    pkg=${depqueue[$i]}; i=$((i + 1))
    [ -z "$pkg" ] && continue
    [ -n "${VISITED[$pkg]:-}" ] && continue
    VISITED[$pkg]=1
    while IFS= read -r dep; do
        real=${REAL[$dep]:-}
        [ -n "$real" ] && [ -z "${VISITED[$real]:-}" ] && depqueue+=("$real")
    done < <(dq -W --showformat='${Depends}|${Pre-Depends}\n' "$pkg" 2>/dev/null \
             | sed 's/([^)]*)//g' | tr ',|' '\n' | sed 's/^[ \t]*//;s/[ \t]*$//;/^$/d')
done

# ---- candidates = installed - closure -------------------------------------
installed=$(dq -W --showformat='${db:Status-Abbrev} ${Package}\n' 2>/dev/null \
    | grep '^ii ' | sed 's/^ii *//' | sort -u)
keep_closure=$(printf '%s\n' "${!VISITED[@]}" | sort -u | sed '/^$/d')
candidates=$(comm -23 <(printf '%s\n' "$installed") <(printf '%s\n' "$keep_closure"))

# ---- gate: every candidate must be classified -----------------------------
classified=$(cat <(strip "$BUILD/keep-packages.txt") \
                 <(strip "$BUILD/purge-packages.txt") \
                 <(strip "$BUILD/purge-packages-late.txt") 2>/dev/null | sort -u | sed '/^$/d')
unclassified=$(comm -23 <(printf '%s\n' "$candidates" | sed '/^$/d') <(printf '%s\n' "$classified"))

if [ -n "$unclassified" ]; then
    echo "audit: purgable packages not classified in build/{keep,purge,purge-packages-late}-packages.txt:" >&2
    printf '%s\n' "$unclassified" | while IFS= read -r p; do
        printf '  %10s KB  %s\n' "$(dq -W --showformat='${Installed-Size}' "$p" 2>/dev/null)" "$p"
    done | sort -rn >&2
    echo "audit: classify each as keep / purge / purge-packages-late, then rebuild." >&2
    exit 1
fi
echo "audit: $(printf '%s\n' "$candidates" | sed '/^$/d' | wc -l) purgable packages, all classified."
