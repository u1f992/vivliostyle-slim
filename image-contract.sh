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

check_vivliostyle_on_path() {
    in_image 'command -v vivliostyle | grep --quiet "^/usr/local/bin/vivliostyle$"'
}

check_vs_alias_on_path() {
    in_image 'command -v vs | grep --quiet "^/usr/local/bin/vs$"'
}

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

check_apt() {
    # Derived images extend the slim base with `RUN apt-get install ...`.
    # The customize-processor docs assume this works on the published image,
    # so apt-get and dpkg must both be present.
    in_image 'apt-get --version && dpkg --version'
}

check_press_ready() {
    in_image 'command -v press-ready'
}

check_gs() {
    in_image 'gs --version'
}

check_poppler_pdftops() {
    in_image 'command -v pdftops'
}

check_xz() {
    # required by @puppeteer/browsers to extract Firefox .tar.xz at runtime
    in_image 'command -v xz'
}

check_unzip() {
    # required by @puppeteer/browsers to extract Chrome .zip at runtime
    in_image 'command -v unzip'
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

# --- browser ------------------------------------------------------------

check_browser_present() {
    # @puppeteer/browsers lays binaries at /opt/puppeteer/<browser>/<version>/<dir>/<binary>
    # (e.g. chrome/<v>/chrome-linux64/chrome, firefox/<v>/firefox/firefox,
    # chrome-headless-shell/<v>/chrome-headless-shell-linux64/chrome-headless-shell).
    # build-rootfs.sh accepts an arbitrary BROWSER value, so probe for any of
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
# Headless PDF generation (the end-to-end test below) exercises only a
# subset of chromium's startup path. The slim image is also expected to
# work behind X11/Wayland forwarding for `vivliostyle preview` and similar
# GUI workflows, so this test spins a minimal Xvfb server in a derived
# container and confirms chromium can initialize against a real X server.
# It catches silent breakage of GTK / X11 / xkb / cursor data files that
# ldd-level checks miss.
check_chrome_gui_init() {
    local tmpdir
    tmpdir=$(mktemp --directory) || return 1
    # The slim image leaves dpkg in a deliberately broken state: keepers still
    # Depend on packages the build purged (debconf, init-system-helpers,
    # libpam-*, libapparmor1, and so on). The design we agreed on: any repair
    # sequence using the container's own apt + dpkg counts. That repair has to
    # be tested somewhere; that somewhere is here.
    #
    # apt --fix-broken install discovers and reinstalls that whole set on its
    # own, straight from the unmet dependencies -- with one exception. perl-base
    # is Essential, and Debian policy lets Essential packages be relied on
    # without being declared as dependencies, so no unmet Depends points at it,
    # apt never selects it, and debconf's postinst then execs its missing Perl
    # frontend and the --fix-broken run dies mid-configure. So bootstrap just
    # perl-base by hand first (apt-get download isn't gated on the broken
    # state), then let --fix-broken repair the rest. Nothing here to keep in
    # sync with the build's purge list.
    cat > "$tmpdir/Dockerfile" <<DOCKERFILE
FROM ${IMAGE}
USER root
RUN apt-get update --quiet=2 \
 && apt-get download perl-base \
 && dpkg --install --force-depends perl-base_*.deb \
 && rm --force perl-base_*.deb \
 && apt-get install --fix-broken --yes --no-install-recommends \
 && apt-get install --yes --no-install-recommends xvfb \
 && rm --recursive --force /var/lib/apt/lists/* \
 && mkdir --parents /tmp/.X11-unix \
 && chmod 1777 /tmp/.X11-unix
USER vivliostyle
DOCKERFILE
    if ! docker build --tag vivcli-gui-contract "$tmpdir" >/tmp/image-contract.gui.build 2>&1; then
        cat /tmp/image-contract.gui.build >&2
        rm --recursive --force "$tmpdir"
        return 1
    fi
    rm --recursive --force "$tmpdir"

    docker run --rm --entrypoint sh vivcli-gui-contract -c '
        Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
        XPID=$!
        sleep 3
        if [ "$(dpkg --print-architecture)" = "amd64" ]; then
            CHROME=$(ls /opt/puppeteer/chrome/*/*/chrome 2>/dev/null | head --lines=1)
        else
            CHROME=/usr/bin/chromium
        fi
        if [ -z "$CHROME" ] || [ ! -x "$CHROME" ]; then
            echo "no chrome binary" >&2; kill $XPID 2>/dev/null; exit 1
        fi
        # Run chromium in GUI mode (NO --headless) against Xvfb. If any GUI
        # subsystem (GTK / X11 / xkb / cursor data / GTK theme) is missing,
        # chromium prints a fatal error and exits within a couple of seconds.
        # If GUI init succeeds, chromium stays alive waiting for input.
        DISPLAY=:99 "$CHROME" --no-sandbox --no-first-run --no-default-browser-check \
            --user-data-dir=/tmp/cdp --disable-gpu \
            about:blank >/tmp/chrome.log 2>&1 &
        CPID=$!
        sleep 8
        if kill -0 $CPID 2>/dev/null; then
            kill $CPID 2>/dev/null
            wait $CPID 2>/dev/null
            kill $XPID 2>/dev/null
            exit 0
        fi
        wait $CPID 2>/dev/null
        echo "chromium died during GUI init; last 20 lines of log:" >&2
        tail --lines=20 /tmp/chrome.log >&2
        kill $XPID 2>/dev/null
        exit 1
    '
    local rc=$?
    docker rmi vivcli-gui-contract >/dev/null 2>&1
    return $rc
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
run_test "vivliostyle on PATH at /usr/local/bin"           check_vivliostyle_on_path
run_test "vs alias on PATH at /usr/local/bin"              check_vs_alias_on_path
run_test "'vivliostyle --version' executes"                check_vivliostyle_version_runs
run_test "'vs --version' executes"                         check_vs_alias_runs

echo "[runtime dependencies]"
run_test "node available"                                  check_node
run_test "npm available (extension contract)"              check_npm
run_test "pnpm available (extension contract)"             check_pnpm
run_test "apt-get + dpkg available (extension contract)"   check_apt
run_test "press-ready resolvable via PATH"                 check_press_ready
run_test "gs (ghostscript) available"                      check_gs
run_test "pdftops (poppler-utils) available"               check_poppler_pdftops
run_test "xz available (Firefox/.tar.xz extraction)"       check_xz
run_test "unzip available (Chrome/.zip extraction)"        check_unzip
run_test "/etc/fonts/local.conf has Noto CJK aliases"      check_fonts_conf_noto_aliases
run_test "Noto CJK JP font is installed"                   check_noto_cjk_font_installed

echo "[browser]"
run_test "Bundled browser binary is present"               check_browser_present
run_test "Puppeteer cache dir is owned by vivliostyle"     check_puppeteer_cache_dir_owned_by_user
run_test "Chrome initializes against an X server (GUI)"    check_chrome_gui_init

echo "[browser install]"
run_test "vivliostyle build --browser chrome@130 (linux/amd64)"   check_cli_install_chrome
run_test "vivliostyle build --browser chromium (linux/amd64)"     check_cli_install_chromium
run_test "vivliostyle build --browser firefox"                    check_cli_install_firefox

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
