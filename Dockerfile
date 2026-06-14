# syntax=docker/dockerfile:1

# Inherit debian:trixie-slim's include/exclude configuration
FROM debian:trixie-slim AS dpkg-excludes
RUN sed 's/^\(path-\(include\|exclude\)\) /\1=/' /etc/dpkg/dpkg.cfg.d/docker > /tmp/trixie-slim.conf

FROM debian:trixie AS builder

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
 && printf '%s' "$(node /tmp/vs-src/build/browser-deps.ts "${distro}")${browser:+ ${browser}}" > /tmp/browser-packages

COPY --from=dpkg-excludes /tmp/trixie-slim.conf /tmp/trixie-slim.conf

# Assemble the rootfs with mmdebstrap
# BuildKit can only grant the needed privilege at the coarse granularity of
# `--allow-insecure-entitlement security.insecure`; the minimal equivalent in
# `docker run` terms is `--cap-add=SYS_ADMIN --security-opt apparmor=unconfined`.
# mmdebstrap bind-mounts /proc, /sys and /dev into the chroot for the package
# maintainer scripts. Those mounts need CAP_SYS_ADMIN, and docker's default
# AppArmor profile (docker-default) also blocks mounting sysfs and devpts.
RUN --security=insecure mmdebstrap \
      --format=dir \
      --variant=custom \
      --dpkgopt=/tmp/trixie-slim.conf \
      # NodeSource ships headers for native module compilation
      --dpkgopt='path-exclude=/usr/include/*' \
      # adduser's postinst expects /run/adduser as its lockfile location
      --setup-hook='mkdir --parents "$1/run"' \
      # Replicate the three files that deb.nodesource.com/setup_*.x writes when
      # adding the NodeSource apt repo: the GPG keyring, the deb822 sources list,
      # and the apt-pinning preferences. We already ran the setup script in the
      # builder stage above, so these files exist on its filesystem; copy them
      # into the same paths inside the target rootfs so apt can resolve 'nodejs'
      # from NodeSource when --include processes it.
      # Source: nodesource/distributions @c6e581b0d24e5d043476ddb947d70e6fe10e83c9
      #   scripts/deb/setup_24.x L64 (nodesource.gpg)
      #   scripts/deb/setup_24.x L83 (nodesource.sources)
      #   scripts/deb/setup_24.x L98 (preferences.d/nodejs)
      --setup-hook='mkdir --parents "$1/usr/share/keyrings" "$1/etc/apt/sources.list.d" "$1/etc/apt/preferences.d"' \
      --setup-hook='cp /usr/share/keyrings/nodesource.gpg "$1/usr/share/keyrings/"' \
      --setup-hook='cp /etc/apt/sources.list.d/nodesource.sources "$1/etc/apt/sources.list.d/"' \
      --setup-hook='cp /etc/apt/preferences.d/nodejs "$1/etc/apt/preferences.d/"' \
      # dpkg-postinst helpers. With --variant=custom the rootfs starts empty,
      # so anything a postinst expects in PATH must be listed explicitly. Each
      # line names a concrete consumer from our installed set (grep over
      # /var/lib/dpkg/info/*.postinst inside the resulting rootfs).
      # dash:      */.postinst start with #!/bin/sh (adduser/dbus/dpkg/..., nearly all).
      # bash:      /usr/bin/ldd is a #!/bin/bash script and usrmerge's postinst
      #            execs 'ldd /bin/cp'.
      # coreutils: rm/cp/ln/mv/mkdir invoked by every nontrivial postinst.
      # diffutils: xz-utils postinst calls diff for conffile management.
      # libc-bin:  libc6 postinst calls ldconfig.
      # perl-base: debconf's /usr/share/debconf/frontend is Perl, sourced via
      #            confmodule by ca-certificates / fontconfig-config / libpaper2 / ...
      # debconf:   base-passwd / ca-certificates / fontconfig-config / libpaper2 /
      #            libpam-* / tzdata / x11-common call db_input or db_get at configure.
      # sed:       ca-certificates / libpam-* / login.defs / python3.13 postinst use sed.
      # grep:      ca-certificates / dbus / passwd / procps / python3.13 / xz-utils
      #            postinst call grep, and image-contract.sh greps the output of
      #            'command -v vivliostyle'.
      # init-system-helpers: dbus / dirmngr / dpkg / gpg / gpg-agent / procps /
      #                      util-linux / x11-common postinst call update-rc.d.
      # util-linux: base-passwd / fontconfig / libpam-runtime / systemd postinst
      #             call util-linux commands (chown via runuser, blkid, ipcs, etc.).
      # mawk:      libpam-runtime / libpam0g / python3.13-minimal postinst call awk.
      # base-files: ships /bin, /etc, /var, ... as the root filesystem skeleton.
      # base-passwd: writes /etc/passwd and /etc/group with root and daemon users;
      #            without it pwck and 'chown root:root' fail.
      # findutils: libgdk-pixbuf-2.0-0 postinst (gdk-pixbuf-query-loaders) calls find.
      # apt: derived images extend with 'FROM ...slim RUN apt-get install <pkg>'
      # (image-contract.sh's check_apt enforces this). apt is also the recovery
      # path for the install-time helpers purged below: if anything ever needs
      # debconf / perl-base / diffutils / mawk / init-system-helpers, a user can
      # pull them back with 'apt-get install <pkg>'.
      --include="dash bash coreutils diffutils libc-bin perl-base debconf sed grep init-system-helpers util-linux mawk \
        base-files base-passwd findutils \
        apt \
        nodejs \
        ca-certificates \
        ghostscript poppler-utils xz-utils unzip \
        fontconfig fonts-noto-core fonts-noto-cjk fonts-noto-cjk-extra \
        $(cat /tmp/browser-packages)" \
      --customize-hook='mkdir --parents "$1/opt" "$1/data" "$1/home/vivliostyle" "$1/usr/lib/node_modules" "$1/usr/local/bin" "$1/etc/fonts"' \
      --customize-hook="printf 'vivliostyle:x:${USER_UID}:${USER_GID}:vivliostyle:/home/vivliostyle:/bin/bash\n' >> \"\$1/etc/passwd\"" \
      --customize-hook="printf 'vivliostyle:x:${USER_GID}:\n' >> \"\$1/etc/group\"" \
      --customize-hook="printf 'vivliostyle:!:19000:0:99999:7:::\n' >> \"\$1/etc/shadow\"" \
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
