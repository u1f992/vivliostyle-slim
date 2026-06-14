# vivliostyle-slim

Pilot release of [vivliostyle/vivliostyle-cli#793](https://github.com/vivliostyle/vivliostyle-cli/pull/793)

`Dockerfile`, `.dockerignore`, `image-contract.sh` and everything under `slim/` are verbatim copies from the PR. Sync them from the PR head with:

```shellsession
$ git fetch https://github.com/vivliostyle/vivliostyle-cli pull/793/head
$ git checkout FETCH_HEAD -- Dockerfile .dockerignore image-contract.sh slim
```

The tag convention is `<cli-ref>-<rev>`. `<cli-ref>` selects a specific commit of Vivliostyle CLI, given as either a tag or a full SHA. Mechanically, the run of digits after the final `-` is `<rev>`. Every `<cli-ref>-<rev>` pair is unique; no moving tags such as `latest` or `11` are published.

## Derived images

The slim build force-purges install-time-only packages, deliberately leaving dpkg broken. Extending the image with `apt-get install` first requires a repair that undoes most of the slim tuning:

```dockerfile
FROM ghcr.io/u1f992/vivliostyle-slim:<tag>
USER root
RUN apt-get update \
 && apt-get download perl-base \
 && dpkg --install --force-depends perl-base_*.deb \
 && rm --force perl-base_*.deb \
 && apt-get install --fix-broken --yes --no-install-recommends \
 && apt-get install --yes --no-install-recommends <packages> \
 && rm --recursive --force /var/lib/apt/lists/*
USER vivliostyle
```

Re-slimming a derived image inherently means redoing the manual curation that went into the vivliostyle-slim image itself. Offering something like a convenience script for re-slimming is impractical, but the vivliostyle-slim build process should serve as a valuable reference.

## Local build

The image is built from the repo-root `Dockerfile`. Its mmdebstrap step runs a
real root chroot and bind-mounts `/proc`, `/sys`, `/dev` for the package
maintainer scripts, which needs `CAP_SYS_ADMIN` and an unconfined profile —
BuildKit exposes that to a `RUN` only through `--security=insecure`. So build
with a `docker-container` builder that allows the entitlement.

Build a single-arch image into the local docker engine as `vivliostyle-slim:local`:

```shellsession
$ git clone https://github.com/vivliostyle/vivliostyle-cli
$ cp -a Dockerfile .dockerignore image-contract.sh vivliostyle-cli/
$ rm -rf vivliostyle-cli/slim
$ cp -a slim vivliostyle-cli/slim
$ cd vivliostyle-cli
$ docker buildx create --driver docker-container \
    --buildkitd-flags '--allow-insecure-entitlement security.insecure' --use
$ docker buildx build \
    --allow security.insecure \
    --build-arg VS_CLI_VERSION=$(jq -r .version package.json) \
    --build-arg BROWSER=chrome@$(sed -n '/START DEFAULT_BROWSER_VERSIONS/,/END DEFAULT_BROWSER_VERSIONS/p' src/constants.ts | grep -oP 'chrome:\s*\K\{[^}]+\}' | jq -r .linux) \
    --tag vivliostyle-slim:local --load .
```

`image-contract.sh` captures the behavior that the upstream container and the slim container must implement alike. Run the contract check against that image with `IMAGE=vivliostyle-slim:local ./image-contract.sh`.
