#!/bin/bash
# Audit tool: list packages in the slim image that aren't in the runtime
# closure (i.e. purge candidates).
#
# This is how the purge list in the Dockerfile was derived. It's
# not part of the image build -- the build hard-codes the hand-vetted
# subset, and per-candidate rationale lives there next to dpkg --purge.
# Re-run when Debian bumps a major release, when a new dependency lands
# in the build, or when something downstream breaks suspiciously; then
# diff against the current purge list.
#
# Usage:
#   IMAGE=vivliostyle/cli:10.5.0-slim ./slim/audit.sh
#   IMAGE=vivliostyle/cli:10.5.0      ./slim/audit.sh   # baseline image
#
# Inner script does this:
#
#   0. Install browsers exercised by image-contract.sh (chrome / chromium
#      / firefox) that aren't already in the image, so their runtime
#      .so trees feed the closure below. The bundle ships one; the rest
#      are downloaded via the CLI's own @puppeteer/browsers.
#
#   1. Seed binaries: each installed browser plus its .so files, node,
#      gs, pdftops, fontconfig binaries, apt + dpkg toolchain (extension
#      contract), vivliostyle wrappers. Everything image-contract.sh
#      exercises at runtime.
#
#   2. Recursive ldd; map each .so to its package via dpkg -S. Linked
#      closure.
#
#   3. Walk Depends + Pre-Depends from the linked closure. Provides is
#      resolved so virtual names ("awk", "debconf-2.0") match the real
#      installed package. Catches keepers ldd doesn't see (helpers we
#      spawn via exec, daemons whose libs aren't seeds but ours link).
#
#   4. Union with a hand-listed data-only set (fonts, xkb-data, icon
#      themes, ICU, poppler-data, ca-certificates, ...). No .so files
#      in those, so ldd skips them; the runtime still reads their
#      /usr/share/* trees.
#
#   5. installed \ (linked ∪ depends ∪ data) = candidates, by size desc.
#
# What this can't see:
#   dlopen. mesa-libgallium, libllvm19, GTK theme engines, libsystemd-shared
#     look orphan because chrome / libsystemd0 dlopen them. firefox does
#     the same with libcloudproviders0 (via libmozgtk at XPCOM init).
#   exec. chrome's sandbox walks /proc via ps; systemd postinsts call
#     update-rc.d. Neither is a link.
#   data via fontconfig / icon-theme / mime cache. Missed unless the
#     owning package is in the hand-listed data set above.

set -eu

IMAGE="${IMAGE:?set IMAGE=<slim image to audit>}"
script_dir=$(cd "$(dirname "$0")" && pwd)

# The actual closure-computation lives in slim/_audit_inner.sh and runs
# inside the audited image. Keeping it as a separate file avoids the quote
# escaping nightmare of inlining bash into 'docker run -c'.
docker run --rm --user 0:0 \
    --volume "$script_dir/_audit_inner.sh":/_audit_inner.sh:ro \
    --entrypoint bash "$IMAGE" /_audit_inner.sh
