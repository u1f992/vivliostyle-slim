#!/bin/bash
# Runs inside the audited image. Invoked by slim/audit.sh -- see that
# wrapper for what this is and why.
set -u

# ---- 0. browsers under contract -----------------------------------------
# image-contract.sh exercises chrome / chromium / firefox installs via
# the CLI. The bundle ships one; install the others now so their .so
# trees feed the ldd closure below and the closure-derived keep set
# protects them from the Dockerfile's purge.
arch=$(dpkg --print-architecture)
if [ "$arch" = "amd64" ] && [ ! -d /opt/puppeteer/chromium ]; then
    /opt/vivliostyle-cli/node_modules/.bin/browsers install chromium \
        --path /opt/puppeteer >/dev/null 2>&1
fi
if [ ! -d /opt/puppeteer/firefox ]; then
    /opt/vivliostyle-cli/node_modules/.bin/browsers install firefox \
        --path /opt/puppeteer >/dev/null 2>&1
fi

# ---- 1. seeds ------------------------------------------------------------
seeds=()
add_seed() { for f in "$@"; do [ -e "$f" ] && seeds+=("$f"); done; }

add_seed /bin/sh /usr/bin/sh /bin/dash /usr/bin/bash /bin/bash
add_seed /usr/bin/node /usr/bin/npm /usr/bin/pnpm /usr/bin/pnpx
add_seed /usr/bin/chromium
for f in /opt/puppeteer/chrome/*/chrome-linux*/chrome \
         /opt/puppeteer/chrome/*/chrome-linux*/chrome-sandbox \
         /opt/puppeteer/chrome/*/chrome-linux*/chrome_crashpad_handler \
         /opt/puppeteer/chromium/*/chrome-linux/chrome \
         /opt/puppeteer/chromium/*/chrome-linux/chrome-sandbox \
         /opt/puppeteer/firefox/*/firefox/firefox \
         /opt/puppeteer/firefox/*/firefox/firefox-bin; do
    add_seed "$f" 2>/dev/null
done
# firefox dispatches a lot of work through libxul + helper .so files
# loaded with $ORIGIN-relative paths; chromium's swiftshader / vulkan
# stack also lives next to chrome. Seed every .so in each install dir
# so the closure visits them.
for d in /opt/puppeteer/firefox/*/firefox \
         /opt/puppeteer/chromium/*/chrome-linux; do
    [ -d "$d" ] || continue
    for so in "$d"/*.so; do
        add_seed "$so" 2>/dev/null
    done
done
add_seed /usr/bin/gs /usr/bin/pdftops /usr/bin/pdfinfo
add_seed /usr/bin/fc-list /usr/bin/fc-match /usr/bin/fc-cache /usr/bin/fc-query
add_seed /usr/bin/unzip /usr/bin/xz /usr/bin/tar
add_seed /usr/bin/apt /usr/bin/apt-get /usr/bin/apt-cache \
         /usr/bin/dpkg /usr/bin/dpkg-deb /usr/bin/dpkg-query
add_seed /usr/local/bin/vivliostyle /usr/local/bin/vs
add_seed /opt/vivliostyle-cli/node_modules/.bin/press-ready

# ---- 2. ldd closure ------------------------------------------------------
closure=/tmp/closure.txt
queue=/tmp/queue.txt
> "$closure"
printf '%s\n' "${seeds[@]}" | sort --unique > "$queue"

while [ -s "$queue" ]; do
    head=$(head --lines=1 "$queue")
    sed --in-place '1d' "$queue"
    grep --quiet --line-regexp --fixed-strings "$head" "$closure" 2>/dev/null && continue
    echo "$head" >> "$closure"

    if [ -L "$head" ]; then
        tgt=$(readlink --canonicalize "$head" 2>/dev/null)
        [ -n "$tgt" ] && ! grep --quiet --line-regexp --fixed-strings "$tgt" "$closure" && echo "$tgt" >> "$queue"
    fi
    if [ -f "$head" ] && [ "$(head --bytes=4 "$head" 2>/dev/null | od --address-radix=n --format=x1 | tr --delete ' \n')" = "7f454c46" ]; then
        # ldd output: '<name> => <path> (<addr>)' or '<path> (<addr>)'. Pull
        # out every whitespace-separated word starting with '/'. We avoid awk
        # because post-purge slim images don't have it (mawk gets purged).
        while IFS= read -r so; do
            grep --quiet --line-regexp --fixed-strings "$so" "$closure" || echo "$so" >> "$queue"
        done < <(ldd "$head" 2>/dev/null | tr --squeeze-repeats ' \t\n' '\n' | grep '^/')
    fi
done

ldd_pkgs=$(sort --unique "$closure" | while read -r f; do
    dpkg --search "$f" 2>/dev/null | cut --delimiter=: --fields=1
done | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort --unique | sed '/^$/d')

# ---- 3. Depends transitive closure ---------------------------------------
visited=/tmp/visited.txt
depqueue=/tmp/depqueue.txt
> "$visited"
printf '%s\n' "$ldd_pkgs" > "$depqueue"
echo "apt" >> "$depqueue"
echo "dpkg" >> "$depqueue"
echo "ca-certificates" >> "$depqueue"

resolve_provides() {
    # Map a (possibly virtual) name to a real installed package via Provides.
    local name="$1"
    if dpkg-query --show --showformat='${Package}\n' "$name" 2>/dev/null | grep --quiet .; then
        echo "$name"
        return
    fi
    for p in $(dpkg-query --show --showformat='${Package}\n' 2>/dev/null); do
        if dpkg-query --show --showformat='${Provides}\n' "$p" 2>/dev/null \
            | grep --quiet --extended-regexp "(^|[, ])$name([ ,(]|$)"; then
            echo "$p"
            return
        fi
    done
}

while [ -s "$depqueue" ]; do
    pkg=$(head --lines=1 "$depqueue")
    sed --in-place '1d' "$depqueue"
    [ -z "$pkg" ] && continue
    grep --quiet --line-regexp --fixed-strings "$pkg" "$visited" && continue
    echo "$pkg" >> "$visited"

    deps=$(dpkg-query --show --showformat='${Depends}|${Pre-Depends}\n' "$pkg" 2>/dev/null)
    echo "$deps" \
        | sed 's/([^)]*)//g' \
        | tr ',|' '\n' \
        | sed 's/^[ \t]*//;s/[ \t]*$//' \
        | grep --invert-match '^$' \
        | while read -r dep; do
            dep_real=$(resolve_provides "$dep")
            if [ -n "$dep_real" ]; then
                grep --quiet --line-regexp --fixed-strings "$dep_real" "$visited" || echo "$dep_real" >> "$depqueue"
            fi
        done
done

runtime_pkgs=$(sort --unique "$visited")

# ---- 4. hand-listed data-only packages -----------------------------------
# These packages have no .so files so the ldd closure cannot see them, but
# the runtime reads files from the /usr/share/* paths they install
# (fontconfig / chrome / gs / poppler / apt's signature verification, ...).
# Update this list when the slim build adds a new data-only package to its
# --include manifest.
data_pkgs="
fonts-liberation
fonts-noto-cjk
fonts-noto-cjk-extra
fonts-noto-core
fonts-noto-mono
fonts-urw-base35
xfonts-encodings
xfonts-utils
poppler-data
libgs-common
libgs10-common
shared-mime-info
fontconfig-config
xkb-data
adwaita-icon-theme
hicolor-icon-theme
gnupg-l10n
debian-archive-keyring
tzdata
media-types
publicsuffix
gpgv
libpaper-utils
"
data_list=$(printf '%s\n' $data_pkgs | sort --unique | sed '/^$/d')

# ---- 5. candidates = installed - (closure ∪ data) ------------------------
# Filter to packages whose Status is 'install ok installed'. dpkg-query -W
# without a filter also lists 'deinstall ok config-files' (purged packages
# whose conffiles remain), which would otherwise pollute the candidate list
# with zombies that no longer consume disk.
all_pkgs=$(dpkg-query --show --showformat='${db:Status-Abbrev} ${Package}\n' 2>/dev/null \
    | grep '^ii ' | sed 's/^ii *//' | sort --unique)
keep=$(printf '%s\n%s\n' "$runtime_pkgs" "$data_list" | sort --unique | sed '/^$/d')
purge=$(comm -23 <(printf '%s\n' "$all_pkgs") <(printf '%s\n' "$keep"))

echo "=== summary ==="
echo "  installed:   $(printf '%s\n' "$all_pkgs" | wc --lines)"
echo "  ldd-derived: $(printf '%s\n' "$ldd_pkgs" | wc --lines)"
echo "  closure:     $(printf '%s\n' "$runtime_pkgs" | wc --lines)"
echo "  data:        $(printf '%s\n' "$data_list" | wc --lines)"
echo "  keep total:  $(printf '%s\n' "$keep" | wc --lines)"
echo "  purge:       $(printf '%s\n' "$purge" | sed '/^$/d' | wc --lines)"
echo
echo "=== candidates (sorted by Installed-Size desc; size in KB) ==="
printf '%s\n' "$purge" | while read -r p; do
    [ -z "$p" ] && continue
    sz=$(dpkg-query --show --showformat='${Installed-Size}' "$p" 2>/dev/null)
    ess=$(dpkg-query --show --showformat='${Essential}' "$p" 2>/dev/null)
    printf "%8s  %-38s  essential=%s\n" "${sz:-0}" "$p" "$ess"
done | sort --reverse --numeric-sort

echo
echo "=== candidate total ==="
total=0
while read -r sz; do
    [ -n "$sz" ] && total=$((total + sz))
done < <(printf '%s\n' "$purge" | xargs --replace={} dpkg-query --show --showformat='${Installed-Size}\n' "{}" 2>/dev/null)
printf "  %d KB (%d MB)\n" "$total" "$((total / 1024))"
