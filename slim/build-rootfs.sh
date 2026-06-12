#!/bin/sh
# Runs inside debian:trixie. Produces a minimal Vivliostyle CLI rootfs.tar.
#
# TARGET_ARCH picks the rootfs architecture. On amd64 we pre-download Chrome
# via Puppeteer. On arm64 we install Debian's `chromium` package instead
# because Chrome-for-Testing has no Linux/arm64 build (puppeteer#12161); the
# CLI hardcodes /usr/bin/chromium for linux_arm at src/browser.ts:316.
set -eu

test "${VS_CLI_VERSION:-}"
test "${TARGET_ARCH:-}"
test "${BROWSER:-}"

case "$TARGET_ARCH" in
    amd64|arm64) ;;
    *) echo "Unsupported TARGET_ARCH: $TARGET_ARCH" >&2; exit 1 ;;
esac

export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"
export TZ="${TZ:-Asia/Tokyo}"
USER_UID="${USER_UID:-1000}"
USER_GID="${USER_GID:-1000}"

# unzip / xz-utils are required by @puppeteer/browsers to extract the
# downloaded browser archives.
apt-get update --quiet=2
apt-get install --yes --no-install-recommends --quiet=2 \
    ca-certificates curl fakechroot fakeroot mmdebstrap arch-test \
    unzip xz-utils >/dev/null

# Run NodeSource's setup script here so we can copy its sources list and
# keyring into the target rootfs.
curl --fail --silent --show-error --location https://deb.nodesource.com/setup_24.x --output /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh >/dev/null
apt-get install --yes --no-install-recommends --quiet=2 nodejs >/dev/null

# slim/ is excluded along with the .dockerignore set: its generated rootfs.tar
# would otherwise recurse into the copy.
{
    printf './.git\n./node_modules\n./slim\n'
    sed -e 's/[[:space:]]*$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
        -e 's#/$##' -e 's#^#./#' /repo/.dockerignore
} > /tmp/copy-excludes
copy_worktree() {
    mkdir --parents "$1"
    tar --create --directory /repo --exclude-from=/tmp/copy-excludes . \
        | tar --extract --directory "$1"
}

npm install --global --silent pnpm

# dist/ is not in the working tree; build it.
rm --recursive --force /tmp/builder
copy_worktree /tmp/builder
( cd /tmp/builder && pnpm install --silent && pnpm build )

# Separate checkout, not the build tree above: a prod install over a completed
# full install keeps valibot's optional `typescript` peer; over a clean tree it
# does not.
rm --recursive --force /tmp/runtime
copy_worktree /tmp/runtime
( cd /tmp/runtime && pnpm install --prod --ignore-scripts --silent )

# Drop native bindings for other platforms (pnpm links them as optional deps,
# none load here). Keep this target's; extend the list when a native module adds
# a platform tuple.
case "$TARGET_ARCH" in
    amd64) KEEP_SUFFIX='-linux-x64-gnu' ;;
    arm64) KEEP_SUFFIX='-linux-arm64-gnu' ;;
esac
ALL_SUFFIXES='
    -linux-x64-gnu -linux-x64-musl
    -linux-arm64-gnu -linux-arm64-musl
    -linux-arm-gnueabihf -linux-riscv64-gnu
    -darwin-x64 -darwin-arm64
    -win32-x64-msvc -win32-arm64-msvc -win32-ia32-msvc
    -android-arm64 -android-arm-eabi
    -freebsd-x64
'
for suf in $ALL_SUFFIXES; do
    [ "$suf" = "$KEEP_SUFFIX" ] && continue
    find /tmp/runtime/node_modules/.pnpm -maxdepth 1 -type d \
        -name "*${suf}@*" -exec rm --recursive --force {} + 2>/dev/null || true
done

# package.json `files` (dist, types) are the runtime payload; the rest of the
# tree is build-time only.
rm --recursive --force /opt/vivliostyle-cli
mkdir --parents /opt/vivliostyle-cli
cp --archive /tmp/runtime/package.json /opt/vivliostyle-cli/package.json
[ -d /tmp/runtime/types ] && cp --archive /tmp/runtime/types /opt/vivliostyle-cli/types
cp --archive /tmp/builder/dist /opt/vivliostyle-cli/dist
cp --archive /tmp/runtime/node_modules /opt/vivliostyle-cli/node_modules
echo "$VS_CLI_VERSION" > /opt/vivliostyle-cli/.vs-cli-version

if [ "$TARGET_ARCH" = "amd64" ]; then
    # Install $BROWSER with the same @puppeteer/browsers the CLI uses.
    mkdir --parents /opt/puppeteer
    /opt/vivliostyle-cli/node_modules/.bin/browsers install "$BROWSER" \
        --path /opt/puppeteer >/dev/null

    # These components are bundled only in branded Chrome / CfT builds, not in Chromium
    # - WidevineCdm (DRM)
    #     https://chromium.googlesource.com/chromium/src/+/149.0.7827.22/third_party/widevine/cdm/widevine.gni#57
    # - MEIPreload (autoplay data)
    #     https://chromium.googlesource.com/chromium/src/+/149.0.7827.22/chrome/browser/component_updater/mei_preload_component_installer.cc#109
    # - PrivacySandboxAttestationsPreloaded (ad-privacy)
    #     https://chromium.googlesource.com/chromium/src/+/149.0.7827.22/chrome/browser/component_updater/privacy_sandbox_attestations_component_installer.cc#38
    # hyphen-data (hyphenation) belongs to this category too, but is excluded
    find /opt/puppeteer -type d \( -name WidevineCdm -o -name MEIPreload \
        -o -name PrivacySandboxAttestationsPreloaded \) -exec rm --recursive --force {} + 2>/dev/null || true

    # UI translations except en-US (LANG=C.UTF-8)
    # Judged safe from the package split Alpine adopts
    # see https://gitlab.alpinelinux.org/alpine/aports/-/blob/v3.23.4/community/chromium/APKBUILD#L983-984
    find /opt/puppeteer -path '*/locales/*.pak' \
        ! -name 'en-US*.pak' -delete 2>/dev/null || true

    # Chrome for Testing ships a `deb.deps` file next to each binary, in
    # apt-get satisfy format. @puppeteer/browsers' --install-deps reads this
    # same file (lib/cjs/install.js:installDeps).
    BROWSER_PACKAGES=$(find /opt/puppeteer -name deb.deps -exec cat {} + \
        | awk '{
              gsub(/\([^)]*\)/, "");   # drop version specifiers (apt --include is name-only)
              sub(/ *\|.*/, "");       # alternatives: pick the first variant
              gsub(/^ +| +$/, "");
              if ($0) print
          }' \
        | sort --unique | tr '\n' ' ')
else
    # arm64: include the Debian `chromium` package and let apt resolve its deps.
    BROWSER_PACKAGES="chromium"
fi
echo "Browser apt packages: $BROWSER_PACKAGES"

# Only amd64 ships the pre-downloaded /opt/puppeteer tree. Park the arch-
# specific hooks as positional args so we can append them to the mmdebstrap
# call below.
set --
if [ "$TARGET_ARCH" = "amd64" ]; then
    set -- "$@" \
        --customize-hook='copy-in /opt/puppeteer /opt/' \
        --customize-hook="chown --recursive ${USER_UID}:${USER_GID} \"\$1/opt/puppeteer\""
fi

cd /slim
rm --force rootfs.tar

mmdebstrap \
    `# Real chroot. fakeroot uses LD_PRELOAD which silently breaks ld.so's` \
    `# RUNPATH resolution, so systemd binaries can't find libsystemd-shared.` \
    --mode=root \
    --format=tar \
    --variant=custom \
    --architectures="$TARGET_ARCH" \
    `# /slim/trixie-slim-dpkg-excludes.conf is the verbatim /etc/dpkg/dpkg.cfg.d/docker pulled` \
    `# from debian:trixie-slim by build.sh (space-separated lines rewritten to` \
    `# the '=' form mmdebstrap parses). mmdebstrap appends a --dpkgopt=<file> to` \
    `# /etc/dpkg/dpkg.cfg.d/99mmdebstrap and, crucially, also feeds the rules to` \
    `# the tarfilter that runs between dpkg-deb --fsys-tarfile and tar --extract.` \
    `# Writing the file ourselves via setup-hook does NOT trigger that filter, so` \
    `# the rules would only apply at dpkg --install time and excluded files would` \
    `# still ship in the rootfs (mmdebstrap source: grep for "99mmdebstrap").` \
    --dpkgopt=/slim/trixie-slim-dpkg-excludes.conf \
    `# Our own addition: NodeSource ships /usr/include/node (~65 MB of C++ headers` \
    `# for native module compilation). Runtime never uses them.` \
    --dpkgopt='path-exclude=/usr/include/*' \
    `# adduser's postinst expects /run/adduser as its lockfile location.` \
    --setup-hook='mkdir --parents "$1/run"' \
    `# Replicate the three files that deb.nodesource.com/setup_*.x writes when` \
    `# adding the NodeSource apt repo: the GPG keyring, the deb822 sources list,` \
    `# and the apt-pinning preferences. We already ran the setup script in the` \
    `# build container above, so these files exist on its filesystem; copy them` \
    `# into the same paths inside the target rootfs so apt can resolve 'nodejs'` \
    `# from NodeSource when --include processes it.` \
    `# Source: nodesource/distributions @c6e581b0d24e5d043476ddb947d70e6fe10e83c9` \
    `#   scripts/deb/setup_24.x L64 (nodesource.gpg)` \
    `#   scripts/deb/setup_24.x L83 (nodesource.sources)` \
    `#   scripts/deb/setup_24.x L98 (preferences.d/nodejs)` \
    --setup-hook='mkdir --parents "$1/usr/share/keyrings" "$1/etc/apt/sources.list.d" "$1/etc/apt/preferences.d"' \
    --setup-hook='cp /usr/share/keyrings/nodesource.gpg "$1/usr/share/keyrings/"' \
    --setup-hook='cp /etc/apt/sources.list.d/nodesource.sources "$1/etc/apt/sources.list.d/"' \
    --setup-hook='cp /etc/apt/preferences.d/nodejs "$1/etc/apt/preferences.d/"' \
    `# dpkg-postinst helpers. With --variant=custom the rootfs starts empty,` \
    `# so anything a postinst expects in PATH must be listed explicitly. Each` \
    `# line names a concrete consumer from our installed set (grep over` \
    `# /var/lib/dpkg/info/*.postinst inside the resulting rootfs).` \
    `# dash:      */.postinst start with #!/bin/sh (adduser/dbus/dpkg/..., nearly all).` \
    `# bash:      /usr/bin/ldd is a #!/bin/bash script and usrmerge's postinst` \
    `#            execs 'ldd /bin/cp'.` \
    `# coreutils: rm/cp/ln/mv/mkdir invoked by every nontrivial postinst.` \
    `# diffutils: xz-utils postinst calls diff for conffile management.` \
    `# libc-bin:  libc6 postinst calls ldconfig.` \
    `# perl-base: debconf's /usr/share/debconf/frontend is Perl, sourced via` \
    `#            confmodule by ca-certificates / fontconfig-config / libpaper2 / ...` \
    `# debconf:   base-passwd / ca-certificates / fontconfig-config / libpaper2 /` \
    `#            libpam-* / tzdata / x11-common call db_input or db_get at configure.` \
    `# sed:       ca-certificates / libpam-* / login.defs / python3.13 postinst use sed.` \
    `# grep:      ca-certificates / dbus / passwd / procps / python3.13 / xz-utils` \
    `#            postinst call grep, and image-contract.sh greps the output of` \
    `#            'command -v vivliostyle'.` \
    `# init-system-helpers: dbus / dirmngr / dpkg / gpg / gpg-agent / procps /` \
    `#                      util-linux / x11-common postinst call update-rc.d.` \
    `# util-linux: base-passwd / fontconfig / libpam-runtime / systemd postinst` \
    `#             call util-linux commands (chown via runuser, blkid, ipcs, etc.).` \
    `# mawk:      libpam-runtime / libpam0g / python3.13-minimal postinst call awk.` \
    `# base-files: ships /bin, /etc, /var, ... as the root filesystem skeleton.` \
    `# base-passwd: writes /etc/passwd and /etc/group with root and daemon users;` \
    `#            without it pwck and 'chown root:root' fail.` \
    `# findutils: libgdk-pixbuf-2.0-0 postinst (gdk-pixbuf-query-loaders) calls find.` \
    `# apt: derived images extend with 'FROM ...slim RUN apt-get install <pkg>'` \
    `# (image-contract.sh's check_apt enforces this). apt is also the recovery` \
    `# path for the install-time helpers purged below: if anything ever needs` \
    `# debconf / perl-base / diffutils / mawk / init-system-helpers, a user can` \
    `# pull them back with 'apt-get install <pkg>'.` \
    --include="dash bash coreutils diffutils libc-bin perl-base debconf sed grep init-system-helpers util-linux mawk \
        base-files base-passwd findutils \
        apt \
        nodejs \
        ca-certificates \
        ghostscript poppler-utils xz-utils unzip \
        fontconfig fonts-noto-core fonts-noto-cjk fonts-noto-cjk-extra \
        $BROWSER_PACKAGES" \
    --customize-hook='mkdir --parents "$1/opt" "$1/data" "$1/home/vivliostyle" "$1/usr/lib/node_modules" "$1/usr/local/bin" "$1/etc/fonts"' \
    --customize-hook="printf 'vivliostyle:x:${USER_UID}:${USER_GID}:vivliostyle:/home/vivliostyle:/bin/bash\n' >> \"\$1/etc/passwd\"" \
    --customize-hook="printf 'vivliostyle:x:${USER_GID}:\n' >> \"\$1/etc/group\"" \
    --customize-hook="printf 'vivliostyle:!:19000:0:99999:7:::\n' >> \"\$1/etc/shadow\"" \
    --customize-hook='copy-in /opt/vivliostyle-cli /opt/' \
    --customize-hook='copy-in /usr/lib/node_modules/pnpm /usr/lib/node_modules/' \
    `# Rename fonts.conf -> local.conf during the copy. copy-in can't do this:` \
    `# it takes the source basename and treats the second arg as a directory.` \
    --customize-hook='cp /repo-build/fonts.conf "$1/etc/fonts/local.conf"' \
    --customize-hook='ln --symbolic --force /opt/vivliostyle-cli/dist/cli.js "$1/usr/local/bin/vivliostyle"' \
    --customize-hook='ln --symbolic --force /opt/vivliostyle-cli/dist/cli.js "$1/usr/local/bin/vs"' \
    `# 'npm install -g' leaves these .cjs files at 644. Normally an npm-generated` \
    `# wrapper supplies the +x; we ship the raw files, so set the bit ourselves.` \
    --customize-hook='chmod +x "$1/usr/lib/node_modules/pnpm/bin/pnpm.cjs" "$1/usr/lib/node_modules/pnpm/bin/pnpx.cjs"' \
    --customize-hook='ln --symbolic --force /usr/lib/node_modules/pnpm/bin/pnpm.cjs "$1/usr/bin/pnpm"' \
    --customize-hook='ln --symbolic --force /usr/lib/node_modules/pnpm/bin/pnpx.cjs "$1/usr/bin/pnpx"' \
    --customize-hook="chown --recursive ${USER_UID}:${USER_GID} \"\$1/data\" \"\$1/opt/vivliostyle-cli\" \"\$1/home/vivliostyle\"" \
    "$@" \
    `# ---- install-time-only package purge ---------------------------------` \
    `# Candidates come from slim/audit.sh (runtime-closure orphans). What's` \
    `# below is the hand-vetted subset. To re-derive: empty this --customize-hook,` \
    `# rebuild, then` \
    `#   IMAGE=vivliostyle/cli:10.5.0-slim-prepurge slim/audit.sh` \
    `#` \
    `# audit.sh flags these as orphan but we keep them (with what audit.sh` \
    `# missed in each case):` \
    `#   coreutils util-linux findutils diffutils grep sed libc-bin` \
    `#     Essentials. dpkg shells out to /usr/bin/diff for conffile management.` \
    `#   libgtk-3-{0t64,common} libgdk-pixbuf-{2.0-0,2.0-common}` \
    `#   libcairo-gobject2 libpangoft2-1.0-0 libpangocairo-1.0-0` \
    `#   libcolord2 libxcursor1 libxinerama1` \
    `#     chrome dlopens these at GUI init (theming, cursors, font shaping).` \
    `#   libepoxy0 libvulkan1 libwayland-{client0,cursor0,egl1}` \
    `#     chrome's GL / Vulkan / Wayland paths; still consulted with --disable-gpu.` \
    `#   dbus dbus-daemon dbus-bin dbus-{system,session,user}-bus-common` \
    `#     chrome attempts a dbus connect on startup; the libs need to resolve` \
    `#     even if the connect fails.` \
    `#   procps libproc2-0` \
    `#     chrome's sandbox + zygote walk /proc through ps.` \
    `#   mount libsmartcols1` \
    `#     util-linux transitive runtime deps.` \
    `#   libsystemd-shared` \
    `#     libsystemd0 dlopens /usr/lib/systemd/libsystemd-shared-<ver>.so.` \
    `#   libcloudproviders0` \
    `#     firefox dlopens this at startup; ldd cannot see the dep.` \
    `#` \
    `# Conversely, audit.sh keeps these, but they can actually be removed` \
    `#   mesa-libgallium libllvm19 libz3-4` \
    `#     system software-GL; Chrome uses its own bundled SwiftShader instead.` \
    `#   adwaita-icon-theme` \
    `#     GTK icon set; surfaces only in GTK dialogs.` \
    `#   python3* libpython3*` \
    `#     NodeSource's nodejs distribution pulls in python so` \
    `#     third-party libraries can use node-gyp, but it brings no` \
    `#     compiler; building native code at "npm install" needs extra` \
    `#     installs anyway, so there is no reason to keep python alone.` \
    `#     see https://github.com/nodejs/node-gyp/blob/v12.3.0/README.md?plain=1#L72` \
    `#` \
    `# Packages are removed from the dependency-graph leaves first,` \
    `# regardless of list order; but Debian lets Essential packages be used` \
    `# implicitly by maintainer scripts without declaring them as dependencies,` \
    `# so under this unusual forced purge a few removal scripts would lose` \
    `# tools they rely on, which are therefore purged in a second pass:` \
    `# - libpam-* postrm scripts call debconf's Perl frontend` \
    `# - python's prerm script calls mawk.` \
    `# see https://salsa.debian.org/dbnpolicy/policy/-/blob/debian/4.7.4.1/policy/ch-binary.rst#L330-337` \
    --customize-hook='chroot "$1" dpkg --purge --force-depends \
        --force-remove-essential --force-remove-protected \
        init-system-helpers \
        mesa-libgallium libllvm19 libz3-4 \
        adwaita-icon-theme \
        python3 python3-minimal python3.13 python3.13-minimal \
        libpython3-stdlib libpython3.13-stdlib libpython3.13-minimal \
        gnupg gnupg-l10n gpg gpg-agent gpgsm gpgconf dirmngr pinentry-curses \
        libnpth0t64 libassuan9 libksba8 \
        xdg-utils wget gtk-update-icon-cache \
        libfontenc1 xfonts-utils xfonts-encodings \
        dconf-service dconf-gsettings-backend libdconf1 \
        libsensors5 libsensors-config libapparmor1 \
        libpam-systemd libpam-modules libpam-modules-bin libpam-runtime libpam0g \
        passwd adduser login.defs liblastlog2-2 \
        systemd systemd-sysv sysvinit-utils' \
    --customize-hook='chroot "$1" dpkg --purge --force-depends \
        --force-remove-essential --force-remove-protected \
        debconf perl-base mawk' \
    trixie rootfs.tar
