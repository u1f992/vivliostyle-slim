# syntax=docker/dockerfile:1

# Inherit debian:13-slim's include/exclude configuration
FROM debian:13-slim AS dpkg-excludes
RUN sed 's/^\(path-\(include\|exclude\)\) /\1=/' /etc/dpkg/dpkg.cfg.d/docker > /tmp/debian-13-slim.conf

FROM debian:13 AS builder

# BuildKit automatic platform ARGs
ARG TARGETARCH

ARG VS_CLI_VERSION
ARG BROWSER
ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Asia/Tokyo
ARG USER_UID=1000
ARG USER_GID=1000
ENV DEBIAN_FRONTEND=${DEBIAN_FRONTEND}
ENV TZ=${TZ}

RUN test "${VS_CLI_VERSION}" \
 && test "${BROWSER}" \
 && case "${TARGETARCH}" in \
      amd64|arm64) ;; \
      *) echo "Unsupported TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
    esac

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
      # to download the NodeSource setup script
      ca-certificates \
      curl \
      # to let @puppeteer/browsers extract browser archives
      unzip \
      xz-utils \
      # to assemble the rootfs
      mmdebstrap \
 && curl --fail --location https://deb.nodesource.com/setup_24.x --output /tmp/nodesource_setup.sh \
 && bash /tmp/nodesource_setup.sh \
 && apt-get install --yes --no-install-recommends \
      nodejs \
 && npm install --global pnpm

COPY . /tmp/vs-src

# Install Vivliostyle CLI
# 1. Static resources
RUN mkdir /tmp/vivliostyle-cli \
 && cd /tmp/vivliostyle-cli \
 && echo "${VS_CLI_VERSION}" > .vs-cli-version \
 && cp --archive /tmp/vs-src/package.json /tmp/vs-src/types .
# 2. Artifacts
RUN cp --archive /tmp/vs-src /tmp/vs-build \
 && cd /tmp/vs-build \
 && pnpm install \
 && pnpm build \
 && cp --archive dist /tmp/vivliostyle-cli/
# 3. Runtime dependencies pruned of foreign-platform packages
RUN cp --archive /tmp/vs-src /tmp/vs-deps \
 && cd /tmp/vs-deps \
 && pnpm install --prod --ignore-scripts \
 && find node_modules/.pnpm -name package.json -type f -exec node /tmp/vs-src/build/prune-foreign.ts "${TARGETARCH}" {} \; \
 && cp --archive node_modules /tmp/vivliostyle-cli/

# Download the browser and resolve its dependency-package list
RUN mkdir /tmp/puppeteer \
 && if [ "${TARGETARCH}" = "amd64" ]; then \
      /tmp/vivliostyle-cli/node_modules/.bin/browsers install "${BROWSER}" --path /tmp/puppeteer \
   && distro=debian13-x64 browser=; \
    else \
      # Chrome for Testing has no linux-arm64 build, so fall back to chromium package
      distro=debian13-arm64 browser=chromium; \
    fi \
 && if [ "${BROWSER%%@*}" = chrome ]; then \
      # These components ship only with branded Chrome and are unneeded at least for Vivliostyle
      rm --recursive --force \
        # WidevineCdm (DRM)
        # see https://chromium.googlesource.com/chromium/src/+/149.0.7827.22/third_party/widevine/cdm/widevine.gni#57
        /tmp/puppeteer/chrome/linux-*/chrome-*/WidevineCdm \
        # MEIPreload (autoplay data)
        # see https://chromium.googlesource.com/chromium/src/+/149.0.7827.22/chrome/browser/component_updater/mei_preload_component_installer.cc#109
        /tmp/puppeteer/chrome/linux-*/chrome-*/MEIPreload \
        # PrivacySandboxAttestationsPreloaded (ad-privacy)
        # see https://chromium.googlesource.com/chromium/src/+/149.0.7827.22/chrome/browser/component_updater/privacy_sandbox_attestations_component_installer.cc#38
        /tmp/puppeteer/chrome/linux-*/chrome-*/PrivacySandboxAttestationsPreloaded \
      # UI translation files are separable, as Alpine's packaging shows.
      # see https://gitlab.alpinelinux.org/alpine/aports/-/blob/v3.23.4/community/chromium/APKBUILD#L983-984
     && { find /tmp/puppeteer/chrome/linux-*/chrome-*/locales -name '*.pak' ! -name 'en-US*.pak' -delete || true; }; \
    fi \
 # @puppeteer/browsers' install-deps is unusable here: it reads a deb.deps file that
 # ships only with Chrome for Testing, so use Playwright's nativeDeps table instead.
 # see https://github.com/puppeteer/puppeteer/blob/browsers-v3.0.4/packages/browsers/src/install.ts#L306-L345
 && curl --fail --location https://raw.githubusercontent.com/microsoft/playwright/v1.60.0/packages/playwright-core/src/server/registry/nativeDeps.ts --output /tmp/nativeDeps.ts \
 && printf '%s' "$(node --input-type=module --eval "const { deps } = await import('/tmp/nativeDeps.ts'); const e = deps['${distro}']; process.stdout.write([...new Set([...e.chromium, ...e.firefox])].join(' '))")${browser:+ ${browser}}" > /tmp/browser-dependencies.txt

COPY --from=dpkg-excludes /tmp/debian-13-slim.conf /tmp/debian-13-slim.conf

# Assemble the rootfs with mmdebstrap
# BuildKit can only grant the needed privilege at the coarse granularity of
# `--allow-insecure-entitlement security.insecure`; the minimal equivalent in
# `docker run` terms is `--cap-add=SYS_ADMIN --security-opt apparmor=unconfined`.
# mmdebstrap bind-mounts /proc, /sys and /dev into the chroot for the package
# maintainer scripts. Those mounts need CAP_SYS_ADMIN, and docker's default
# AppArmor profile (docker-default) also blocks mounting sysfs and devpts.
RUN --security=insecure \
    ESSENTIAL="$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' /tmp/vs-src/build/essential-packages.txt)" \
 && mmdebstrap \
      --format=dir \
      --variant=custom \
      --dpkgopt=/tmp/debian-13-slim.conf \
      # NodeSource ships headers for native module compilation
      --dpkgopt='path-exclude=/usr/include/*' \
      # adduser's postinst expects /run/adduser as its lockfile location
      --setup-hook='mkdir "$1/run"' \
      # Set up the NodeSource apt repo
      # see https://github.com/nodesource/distributions/blob/c6e581b0d24e5d043476ddb947d70e6fe10e83c9/scripts/deb/setup_24.x
      --setup-hook=' \
        mkdir --parents "$1/usr/share/keyrings" "$1/etc/apt/sources.list.d" "$1/etc/apt/preferences.d" \
     && cp /usr/share/keyrings/nodesource.gpg "$1/usr/share/keyrings/" \
     && cp /etc/apt/sources.list.d/nodesource.sources "$1/etc/apt/sources.list.d/" \
     && cp /etc/apt/preferences.d/nodejs "$1/etc/apt/preferences.d/"' \
      --include="$ESSENTIAL \
        # ---
        # groupadd/useradd for the user-creation hook below.
        passwd \
        # recovery point for derived images
        apt \
        # Chrome / Firefox requirements
        $(cat /tmp/browser-dependencies.txt) \
        # Vivliostyle CLI requirements
        nodejs \
        # press-ready requirements
        ghostscript \
        poppler-utils \
        # @puppeteer/browsers requirements
        unzip \
        xz-utils \
        # TODO: should such a large font set be bundled into the image?
        # see https://github.com/vivliostyle/vivliostyle-cli/blob/v11.0.2/Dockerfile#L42-L43
        $(apt-cache show fonts-noto | sed -nE 's/^(Depends|Recommends): //p')" \
      --customize-hook='mkdir --parents "$1/opt" "$1/data" "$1/usr/lib/node_modules" "$1/usr/local/bin" "$1/etc/fonts"' \
      # Create the runtime user
      --customize-hook=" \
        chroot \"\$1\" groupadd --gid ${USER_GID} vivliostyle \
     && chroot \"\$1\" useradd --uid ${USER_UID} --gid vivliostyle --home /home/vivliostyle --no-create-home vivliostyle \
     && mkdir \"\$1/home/vivliostyle\"" \
      --customize-hook='copy-in /tmp/vivliostyle-cli /opt/' \
      --customize-hook='copy-in /usr/lib/node_modules/pnpm /usr/lib/node_modules/' \
      # Rename fonts.conf -> local.conf during the copy. copy-in can't do this:
      # it takes the source basename and treats the second arg as a directory.
      --customize-hook='cp /tmp/vs-src/build/fonts.conf "$1/etc/fonts/local.conf"' \
      --customize-hook='ln --symbolic --force /opt/vivliostyle-cli/dist/cli.js "$1/usr/local/bin/vivliostyle"' \
      --customize-hook='ln --symbolic --force /opt/vivliostyle-cli/dist/cli.js "$1/usr/local/bin/vs"' \
      # 'npm install -g' leaves these .cjs files at 644. Normally an npm-generated
      # wrapper supplies the +x; we ship the raw files, so set the bit ourselves.
      --customize-hook='chmod +x "$1/usr/lib/node_modules/pnpm/bin/pnpm.cjs" "$1/usr/lib/node_modules/pnpm/bin/pnpx.cjs"' \
      --customize-hook='ln --symbolic --force /usr/lib/node_modules/pnpm/bin/pnpm.cjs "$1/usr/bin/pnpm"' \
      --customize-hook='ln --symbolic --force /usr/lib/node_modules/pnpm/bin/pnpx.cjs "$1/usr/bin/pnpx"' \
      --customize-hook="chown --recursive ${USER_UID}:${USER_GID} \"\$1/data\" \"\$1/opt/vivliostyle-cli\" \"\$1/home/vivliostyle\"" \
      --customize-hook='copy-in /tmp/puppeteer /opt/' \
      --customize-hook="chown --recursive ${USER_UID}:${USER_GID} \"\$1/opt/puppeteer\"" \
      # ---- install-time-only package purge ---------------------------------
      # Candidates come from slim/audit.sh (runtime-closure orphans). What's
      # below is the hand-vetted subset. To re-derive: empty this --customize-hook,
      # rebuild, then
      #   IMAGE=vivliostyle/cli:10.5.0-slim-prepurge slim/audit.sh
      #
      # audit.sh flags these as orphan but we keep them (with what audit.sh
      # missed in each case):
      #   coreutils util-linux findutils diffutils grep sed libc-bin
      #     Essentials. dpkg shells out to /usr/bin/diff for conffile management.
      #   libgtk-3-{0t64,common} libgdk-pixbuf-{2.0-0,2.0-common}
      #   libcairo-gobject2 libpangoft2-1.0-0 libpangocairo-1.0-0
      #   libcolord2 libxcursor1 libxinerama1
      #     chrome dlopens these at GUI init (theming, cursors, font shaping).
      #   libepoxy0 libvulkan1 libwayland-{client0,cursor0,egl1}
      #     chrome's GL / Vulkan / Wayland paths; still consulted with --disable-gpu.
      #   dbus dbus-daemon dbus-bin dbus-{system,session,user}-bus-common
      #     chrome attempts a dbus connect on startup; the libs need to resolve
      #     even if the connect fails.
      #   procps libproc2-0
      #     chrome's sandbox + zygote walk /proc through ps.
      #   mount libsmartcols1
      #     util-linux transitive runtime deps.
      #   libsystemd-shared
      #     libsystemd0 dlopens /usr/lib/systemd/libsystemd-shared-<ver>.so.
      #   libcloudproviders0
      #     firefox dlopens this at startup; ldd cannot see the dep.
      #
      # Conversely, audit.sh keeps these, but they can actually be removed
      #   mesa-libgallium libllvm19 libz3-4
      #     system software-GL; Chrome uses its own bundled SwiftShader instead.
      #   adwaita-icon-theme
      #     GTK icon set; surfaces only in GTK dialogs.
      #   python3* libpython3*
      #     NodeSource's nodejs distribution pulls in python so
      #     third-party libraries can use node-gyp, but it brings no
      #     compiler; building native code at "npm install" needs extra
      #     installs anyway, so there is no reason to keep python alone.
      #     see https://github.com/nodejs/node-gyp/blob/v12.3.0/README.md?plain=1#L72
      #
      # Packages are removed from the dependency-graph leaves first,
      # regardless of list order; but Debian lets Essential packages be used
      # implicitly by maintainer scripts without declaring them as dependencies,
      # so under this unusual forced purge a few removal scripts would lose
      # tools they rely on, which are therefore purged in a second pass:
      # - libpam-* postrm scripts call debconf's Perl frontend
      # - python's prerm script calls mawk.
      # - python3*'s postrm runs the Python interpreter (libpython3*).
      # see https://salsa.debian.org/dbnpolicy/policy/-/blob/debian/4.7.4.1/policy/ch-binary.rst#L330-337
      --customize-hook='chroot "$1" dpkg --purge --force-depends \
        --force-remove-essential --force-remove-protected \
        init-system-helpers \
        mesa-libgallium libllvm19 libz3-4 \
        adwaita-icon-theme \
        python3 python3-minimal python3.13 python3.13-minimal \
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
        debconf perl-base mawk \
        libpython3-stdlib libpython3.13-stdlib libpython3.13-minimal' \
      trixie /rootfs

FROM scratch
COPY --from=builder /rootfs/ /
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PATH=/opt/vivliostyle-cli/node_modules/.bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER vivliostyle
WORKDIR /data
ENTRYPOINT ["vivliostyle"]
