#!/usr/bin/env bash
# Verifies the container contract of a Vivliostyle CLI image.
#
# Usage:
#   IMAGE="vivliostyle/cli:10.5.0" ./image-contract.sh
#
# The contract is derived from the Dockerfile and source code that consumes
# it (src/container.ts, src/util.ts isInContainer, src/browser.ts, the
# customize-processor example, etc.).

set -uo pipefail

IMAGE="${IMAGE:-ghcr.io/vivliostyle/cli:10.5.0}"

pass=0
fail=0
total=0
failed_names=()

run_test() {
    local name="$1"
    shift
    total=$((total + 1))
    if "$@" >/tmp/image-contract.out 2>&1; then
        echo "  ok  - $name"
        pass=$((pass + 1))
    else
        echo "  FAIL- $name"
        sed 's/^/        | /' /tmp/image-contract.out
        fail=$((fail + 1))
        failed_names+=("$name")
    fi
}

in_image() {
    docker run --rm --entrypoint sh "$IMAGE" -c "$1"
}

# --- metadata -----------------------------------------------------------

check_entrypoint() {
    local ep
    ep=$(docker inspect --format '{{json .Config.Entrypoint}}' "$IMAGE")
    [ "$ep" = '["vivliostyle"]' ]
}

check_workdir() {
    local wd
    wd=$(docker inspect --format '{{.Config.WorkingDir}}' "$IMAGE")
    [ "$wd" = "/data" ]
}

check_user_metadata() {
    local u
    u=$(docker inspect --format '{{.Config.User}}' "$IMAGE")
    [ "$u" = "vivliostyle" ]
}

check_lang() {
    docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$IMAGE" \
        | grep --quiet '^LANG=C.UTF-8$'
}

check_path_includes_node_modules_bin() {
    docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "$IMAGE" \
        | grep --quiet '/opt/vivliostyle-cli/node_modules/.bin'
}

# --- runtime identity ---------------------------------------------------

check_runtime_uid_gid() {
    local out
    out=$(in_image 'id --user; id --group; id --user --name')
    printf '%s\n' "$out" | sed --quiet '1p' | grep --quiet --line-regexp 1000 || return 1
    printf '%s\n' "$out" | sed --quiet '2p' | grep --quiet --line-regexp 1000 || return 1
    printf '%s\n' "$out" | sed --quiet '3p' | grep --quiet --line-regexp vivliostyle
}

check_vs_cli_version_marker() {
    # src/util.ts isInContainer() reads this file.
    local v
    v=$(in_image 'cat /opt/vivliostyle-cli/.vs-cli-version')
    [ -n "$v" ]
}

check_data_dir_writable_by_user() {
    in_image 'test -d /data && touch /data/.probe && rm /data/.probe'
}

# --- CLI entry points ---------------------------------------------------

check_vivliostyle_version_runs() {
    docker run --rm "$IMAGE" --version >/dev/null
}

check_vs_alias_runs() {
    docker run --rm --entrypoint vs "$IMAGE" --version >/dev/null
}

# --- runtime dependencies (Dockerfile-installed) ------------------------

check_node() {
    in_image 'node --version'
}

check_npm() {
    # customize-processor example: users add packages to their own project
    # and need a package manager available in the container.
    in_image 'npm --version'
}

check_pnpm() {
    in_image 'pnpm --version'
}

# --- press-ready (PDF/X-1a preflight) ------------------------------------
# The contract is that press-ready runs end to end, not that gs/poppler exist on
# PATH -- a `command -v` check passes even for a present-but-unloadable binary,
# as the purged-libassuan poppler breakage showed.
check_press_ready_pdf() {
    local tmpdir rc=0
    tmpdir=$(mktemp --directory)
    chmod 777 "$tmpdir"
    cat >"$tmpdir/manuscript.md" <<'EOF'
# Hello

press-ready contract test.
EOF
    cat >"$tmpdir/vivliostyle.config.js" <<'EOF'
export default {
  title: 'press-ready',
  entry: ['manuscript.md'],
  output: 'out.pdf',
  pdfPostprocess: { preflight: 'press-ready' },
};
EOF
    docker run --rm --volume "$tmpdir":/data "$IMAGE" build || rc=$?
    if [ $rc -ne 0 ] || [ ! -f "$tmpdir/out.pdf" ] \
       || ! head --bytes=4 "$tmpdir/out.pdf" | grep --quiet '^%PDF'; then
        echo "press-ready build rc=$rc"
        ls --format=long --all "$tmpdir" >&2 || true
        rm --recursive --force "$tmpdir"
        return 1
    fi
    # press-ready rewrites the PDF with Ghostscript, so a Ghostscript producer
    # proves it ran rather than being skipped.
    local producer
    producer=$(docker run --rm --volume "$tmpdir":/data --entrypoint pdfinfo "$IMAGE" /data/out.pdf 2>/dev/null \
               | sed --quiet 's/^Producer:[[:space:]]*//p')
    rm --recursive --force "$tmpdir"
    case "$producer" in
        *Ghostscript*) return 0 ;;
        *) echo "press-ready did not run: producer='${producer}' (expected Ghostscript)" >&2; return 1 ;;
    esac
}

check_fonts_conf_noto_aliases() {
    in_image '
        test -f /etc/fonts/local.conf \
        && grep --quiet "Noto Serif CJK JP" /etc/fonts/local.conf \
        && grep --quiet "Noto Sans CJK JP"  /etc/fonts/local.conf'
}

check_noto_cjk_font_installed() {
    in_image 'fc-list | grep --quiet --ignore-case "Noto Serif CJK JP"'
}

check_font_file_loadable() {
    in_image "fc-list | grep --quiet --fixed-strings '$1'"
}

# --- browser ------------------------------------------------------------

check_browser_present() {
    # @puppeteer/browsers lays binaries at /opt/puppeteer/<browser>/<version>/<dir>/<binary>
    # (e.g. chrome/<v>/chrome-linux64/chrome, firefox/<v>/firefox/firefox,
    # chrome-headless-shell/<v>/chrome-headless-shell-linux64/chrome-headless-shell).
    # the Dockerfile accepts an arbitrary BROWSER value, so probe for any of
    # the binaries @puppeteer/browsers can drop here rather than hard-coding chrome.
    in_image '
        if [ "$(dpkg --print-architecture)" = "amd64" ]; then
            ls /opt/puppeteer/chrome/*/*/chrome \
               /opt/puppeteer/firefox/*/*/firefox \
               /opt/puppeteer/chrome-headless-shell/*/*/chrome-headless-shell \
               2>/dev/null | grep --quiet .
        else
            command -v chromium >/dev/null
        fi'
}

check_puppeteer_cache_dir_owned_by_user() {
    in_image '
        if [ "$(dpkg --print-architecture)" = "amd64" ]; then
            test -d /opt/puppeteer && [ "$(stat --format=%U /opt/puppeteer)" = "vivliostyle" ]
        else
            true
        fi'
}

# --- GUI / X11 reachability ----------------------------------------------
# The slim image must open a real, non-headless GUI window via `vivliostyle
# preview`, not just render headless PDFs. It ships no X server and must stay as
# shipped (no install/repair), so a throwaway sidecar provides one and the
# unmodified slim container draws to it.

# check_preview_gui <browser-arg>
check_preview_gui() {
    local browser_arg="$1"
    local suffix sc pr code ready=0 deadline
    suffix=$(printf '%s' "$browser_arg" | tr --complement 'a-z0-9' '-')
    sc="vivcli-xvfb-$$-${suffix}"   # $$: unique per run -> no clash with an interrupt's leftovers
    pr="vivcli-preview-$$-${suffix}"

    # The sidecar is also the judge: it exits 0 once a client window maps, 1 on
    # timeout. (chromium maps helper windows before xlsclients lists them, hence
    # the xwininfo fallback.)
    docker run --rm --detach --name "$sc" debian:13-slim sh -c '
        apt-get update --quiet=2 >/dev/null 2>&1 || exit 1
        apt-get install --yes --no-install-recommends xvfb x11-utils >/dev/null 2>&1 || exit 1
        Xvfb :99 -screen 0 1024x768x24 -ac -nolisten tcp &
        i=0
        while [ "$i" -lt 240 ]; do
            if [ -n "$(xlsclients -display :99 2>/dev/null)" ] || [ "$(xwininfo -root -children -display :99 2>/dev/null | grep -cE "^[[:space:]]+0x[0-9a-f]+")" -gt 0 ]; then
                exit 0
            fi
            i=$((i + 1)); sleep 1
        done
        exit 1
    ' >/dev/null 2>&1

    deadline=$((SECONDS + 120))
    while [ "$SECONDS" -lt "$deadline" ]; do
        docker inspect --format '{{.State.Running}}' "$sc" 2>/dev/null \
            | grep --quiet true || break
        if docker exec "$sc" xdpyinfo -display :99 >/dev/null 2>&1; then
            ready=1
            break
        fi
        sleep 1
    done
    if [ "$ready" -ne 1 ]; then
        echo "Xvfb sidecar did not become ready" >&2
        docker logs "$sc" >&2 2>&1 || true
        return 1
    fi

    # --network: reach Xvfb over the shared netns's abstract socket (no volume).
    # --pid: the probe dies and --rm's with the sidecar, so there is no teardown
    # (safe only because the CLI launches chrome with --no-sandbox).
    docker run --rm --detach --name "$pr" \
        --network "container:$sc" --pid "container:$sc" \
        --env DISPLAY=:99 \
        "$IMAGE" preview --browser "$browser_arg" >/dev/null 2>&1

    code=$(docker wait "$sc" 2>/dev/null)
    if [ "$code" != 0 ]; then
        echo "no GUI window appeared for 'vivliostyle preview --browser ${browser_arg}'" >&2
        docker logs "$pr" >&2 2>&1 | tail --lines=30 || true
        return 1
    fi
    return 0
}

# --- browser install ----------------------------------------------------
# The CLI installs a browser when --browser requests one not already in
# the image. The image must support this for each of the three browsers
# the CLI advertises.

cli_install_probe() {
    local browser_arg="$1"
    local tmpdir rc=0
    tmpdir=$(mktemp --directory)
    chmod 777 "$tmpdir"
    cat >"$tmpdir/manuscript.md" <<'EOF'
# Hello

Browser install contract end-to-end test.
EOF
    cat >"$tmpdir/vivliostyle.config.js" <<'EOF'
export default {
  title: 'install',
  entry: ['manuscript.md'],
  output: 'out.pdf',
};
EOF
    docker run --rm --volume "$tmpdir":/data "$IMAGE" \
        build --browser "$browser_arg" || rc=$?
    if [ $rc -eq 0 ] && [ -f "$tmpdir/out.pdf" ] \
       && head --bytes=4 "$tmpdir/out.pdf" | grep --quiet '^%PDF'; then
        rm --recursive --force "$tmpdir"
        return 0
    fi
    echo "build rc=$rc"
    ls --format=long --all "$tmpdir" >&2 || true
    rm --recursive --force "$tmpdir"
    return 1
}

check_cli_install_chrome() {
    # Pin to a Chrome major below the bundled one. Bundled versions only
    # move forward across releases, so this is guaranteed to differ from
    # the bundle and from @stable, forcing the install code path. On
    # linux/arm64 the CLI redirects chrome to /usr/bin/chromium
    # (src/browser.ts:308-316) and the install path is unreachable.
    local arch
    arch=$(docker inspect --format '{{.Architecture}}' "$IMAGE")
    if [ "$arch" = "arm64" ]; then return 0; fi
    cli_install_probe chrome@130
}

check_cli_install_chromium() {
    # Same arm64 fallback as chrome.
    local arch
    arch=$(docker inspect --format '{{.Architecture}}' "$IMAGE")
    if [ "$arch" = "arm64" ]; then return 0; fi
    cli_install_probe chromium
}

check_cli_install_firefox() {
    cli_install_probe firefox
}

# --- end-to-end ---------------------------------------------------------

check_end_to_end_pdf_build() {
    local tmpdir
    tmpdir=$(mktemp --directory)
    chmod 777 "$tmpdir"
    cat >"$tmpdir/manuscript.md" <<'EOF'
# Hello

Container contract end-to-end test.
EOF
    cat >"$tmpdir/vivliostyle.config.js" <<'EOF'
export default {
  title: 'contract',
  entry: ['manuscript.md'],
  output: 'out.pdf',
};
EOF
    local rc=0
    docker run --rm --volume "$tmpdir":/data "$IMAGE" build || rc=$?
    if [ $rc -eq 0 ] && [ -f "$tmpdir/out.pdf" ] && head --bytes=4 "$tmpdir/out.pdf" | grep --quiet '^%PDF'; then
        rm --recursive --force "$tmpdir"
        return 0
    fi
    echo "build rc=$rc"
    ls --format=long --all "$tmpdir" >&2 || true
    rm --recursive --force "$tmpdir"
    return 1
}

# --- derived-image extension (apt repair) -------------------------------
# git is the right probe: it is absent from the image and Depends on perl, which
# the build purged, so installing it only works if the repair pulls that purged
# dependency back in. Running git (not just installing it) then confirms the
# result is actually executable.
check_apt_repair_install() {
    docker run --rm --user root --entrypoint sh "$IMAGE" -c '
        set -e
        apt-get update
        apt-get download perl-base
        dpkg --install --force-depends perl-base_*.deb
        rm --force perl-base_*.deb
        apt-get install --fix-broken --yes --no-install-recommends
        apt-get install --yes --no-install-recommends git
        rm --recursive --force /var/lib/apt/lists/*
        git --version >/dev/null
        perl --version >/dev/null
        for p in git perl liberror-perl perl-base; do
            dpkg -s "$p" 2>/dev/null | grep --quiet "^Status: install ok installed" \
                || { echo "$p is not cleanly installed" >&2; exit 1; }
        done
        work=$(mktemp -d)
        cd "$work"
        git init --quiet
        git -c user.email=contract@example.com -c user.name=contract \
            commit --allow-empty --quiet --message probe
        git log --oneline >/dev/null
    '
}

# --- run ----------------------------------------------------------------

echo "Image: $IMAGE"
echo

echo "[metadata]"
run_test "Entrypoint is [\"vivliostyle\"]"                 check_entrypoint
run_test "WORKDIR is /data"                                check_workdir
run_test "Config.User is vivliostyle"                      check_user_metadata
run_test "LANG=C.UTF-8"                                    check_lang
run_test "PATH includes node_modules/.bin"                 check_path_includes_node_modules_bin

echo "[runtime identity]"
run_test "Runtime UID/GID/name = 1000/1000/vivliostyle"    check_runtime_uid_gid
run_test ".vs-cli-version marker exists (isInContainer)"   check_vs_cli_version_marker
run_test "/data is writable by the runtime user"           check_data_dir_writable_by_user

echo "[CLI entry points]"
run_test "'vivliostyle --version' executes"                check_vivliostyle_version_runs
run_test "'vs --version' executes"                         check_vs_alias_runs

echo "[runtime dependencies]"
run_test "node available"                                  check_node
run_test "npm available (extension contract)"              check_npm
run_test "pnpm available (extension contract)"             check_pnpm
run_test "/etc/fonts/local.conf has Noto CJK aliases"      check_fonts_conf_noto_aliases
run_test "Noto CJK JP font is installed"                   check_noto_cjk_font_installed

echo "[fonts: full Noto set]"
run_test "fonts-noto-core loadable (NotoSans-Regular.ttf)"            check_font_file_loadable NotoSans-Regular.ttf
run_test "fonts-noto-cjk loadable (NotoSansCJK-Regular.ttc)"          check_font_file_loadable NotoSansCJK-Regular.ttc
run_test "fonts-noto-cjk-extra loadable (NotoSansCJK-Thin.ttc)"       check_font_file_loadable NotoSansCJK-Thin.ttc
run_test "fonts-noto-color-emoji loadable (NotoColorEmoji.ttf)"       check_font_file_loadable NotoColorEmoji.ttf
run_test "fonts-noto-extra loadable (NotoKufiArabic-Black.ttf)"       check_font_file_loadable NotoKufiArabic-Black.ttf
run_test "fonts-noto-mono loadable (NotoMono-Regular.ttf)"            check_font_file_loadable NotoMono-Regular.ttf
run_test "fonts-noto-ui-core loadable (NotoLoopedLaoUI-Bold.ttf)"     check_font_file_loadable NotoLoopedLaoUI-Bold.ttf
run_test "fonts-noto-ui-extra loadable (NotoLoopedLaoUI-Black.ttf)"   check_font_file_loadable NotoLoopedLaoUI-Black.ttf

echo "[browser]"
run_test "Bundled browser binary is present"               check_browser_present
run_test "Puppeteer cache dir is owned by vivliostyle"     check_puppeteer_cache_dir_owned_by_user

echo "[browser GUI: preview opens a window on an external X server]"
run_test "preview --browser chrome opens a GUI window"     check_preview_gui chrome
run_test "preview --browser chromium opens a GUI window"   check_preview_gui chromium
run_test "preview --browser firefox opens a GUI window"    check_preview_gui firefox

echo "[browser install]"
run_test "vivliostyle build --browser chrome@130 (linux/amd64)"   check_cli_install_chrome
run_test "vivliostyle build --browser chromium (linux/amd64)"     check_cli_install_chromium
run_test "vivliostyle build --browser firefox"                    check_cli_install_firefox

echo "[derived image extension]"
run_test "derived image repair + 'apt-get install git' (git & perl run)"   check_apt_repair_install

echo "[press-ready]"
run_test "press-ready preflight runs end-to-end (gs + poppler)"   check_press_ready_pdf

echo "[end-to-end]"
run_test "vivliostyle build produces a valid PDF"          check_end_to_end_pdf_build

echo
echo "Total: $total  Pass: $pass  Fail: $fail"
if [ "$fail" -gt 0 ]; then
    printf '\nFailed tests:\n'
    for n in "${failed_names[@]}"; do
        printf '  - %s\n' "$n"
    done
    exit 1
fi
