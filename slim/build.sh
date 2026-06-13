#!/bin/sh
# Build entry point for the slim image. Runs build-rootfs.sh in a
# debian:trixie container, then imports the resulting tar as an image.
#
# BUILD-side inputs (VS_CLI_VERSION, TARGET_ARCH, BROWSER, ...) come from
# the caller, same as how .github/workflows/cd-workflow.yml passes build-args
# to the Dockerfile. build-rootfs.sh validates them with `test $X`. build.sh
# only owns the image name and tag.
set -eu

test "${IMAGE_NAME:-}"
test "${TAG_NAME:-}"
# Needed up-front for the build container's --platform flag below.
# build-rootfs.sh validates it again and rejects values other than amd64/arm64.
test "${TARGET_ARCH:-}"

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)

# Pull the official slim dpkg exclude list directly from debian:trixie-slim
# (the upstream "what's safe to drop in a container" reference). The upstream
# file uses space-separated 'path-exclude PATTERN' syntax; we rewrite to
# 'path-exclude=PATTERN' which mmdebstrap and dpkg honor consistently in
# /etc/dpkg/dpkg.cfg.d. build-rootfs.sh installs the result before apt runs.
docker run --rm --entrypoint cat debian:trixie-slim /etc/dpkg/dpkg.cfg.d/docker \
    | sed 's/^\(path-\(include\|exclude\)\) /\1=/' \
    > "$script_dir/trixie-slim-dpkg-excludes.conf"

# Run the builder under the TARGET_ARCH platform so pnpm pulls the correct
# native binaries for packages like @napi-rs/canvas and @u1f992/mupdf. Without
# this, an amd64 host building TARGET_ARCH=arm64 would install amd64 native
# modules into an arm64 rootfs and crash at runtime. Cross-arch runs require
# binfmt_misc on the host (e.g. tonistiigi/binfmt, or docker/setup-qemu-action
# in CI); same-arch runs are no-ops.
#
# `--env VAR` (no value) only forwards VAR if it is set in the caller's
# environment. Unset vars stay unset inside the container, so build-rootfs.sh
# decides defaults and required-checks on its own.
#
# mmdebstrap bind-mounts /proc, /sys and /dev into the chroot for the package
# maintainer scripts. Those mounts need CAP_SYS_ADMIN, and docker's default
# AppArmor profile (docker-default) also blocks mounting sysfs and devpts.
docker run --rm \
    --platform="linux/${TARGET_ARCH}" \
    --cap-add=SYS_ADMIN \
    --security-opt apparmor=unconfined \
    --mount type=bind,source="$script_dir",target=/slim \
    --mount type=bind,source="$repo_root/build",target=/repo-build,readonly \
    --mount type=bind,source="$repo_root",target=/repo,readonly \
    --workdir /slim \
    --env VS_CLI_VERSION \
    --env TARGET_ARCH \
    --env BROWSER \
    --env DEBIAN_FRONTEND \
    --env TZ \
    --env USER_UID \
    --env USER_GID \
    debian:trixie /slim/build-rootfs.sh

# docker import defaults Os/Architecture in image metadata to the host's, which
# would tag an arm64 rootfs as linux/amd64 when this script runs on an amd64
# host. On a real arm64 host that image then fails with "exec format error".
# Stamp the architecture explicitly so the image manifest matches its contents.
cat "$script_dir/rootfs.tar" | docker import \
    --platform="linux/${TARGET_ARCH}" \
    --change 'ENV LANG=C.UTF-8' \
    --change 'ENV LC_ALL=C.UTF-8' \
    --change 'ENV PATH=/opt/vivliostyle-cli/node_modules/.bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
    --change 'USER vivliostyle' \
    --change 'WORKDIR /data' \
    --change 'ENTRYPOINT ["vivliostyle"]' \
    - "${IMAGE_NAME}:${TAG_NAME}"

echo
docker image ls "${IMAGE_NAME}:${TAG_NAME}"
