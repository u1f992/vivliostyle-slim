# vivliostyle-slim

Pilot release of [vivliostyle/vivliostyle-cli#793](https://github.com/vivliostyle/vivliostyle-cli/pull/793)

The tag convention is `<cli-ref>-<rev>`. `<cli-ref>` selects a specific commit of Vivliostyle CLI, given as either a tag or a full SHA. Mechanically, the run of digits after the final `-` is `<rev>`. Every `<cli-ref>-<rev>` pair is unique; no moving tags such as `latest` or `11` are published.

## Fonts

Since v11.0.4-3 the image bundles no font packages. The only installed face is [Adobe NotDef](https://github.com/adobe-fonts/adobe-notdef), so every glyph no font covers renders as a visible tofu box instead of falling back to a substitute ([vivliostyle/vivliostyle-cli#832](https://github.com/vivliostyle/vivliostyle-cli/issues/832)). Provide the fonts your document uses yourself: bundle them in the project and reference them with `@font-face`, or mount them under `/usr/share/fonts`:

```
$ docker run --rm --volume .:/data --volume ./fonts:/usr/share/fonts/mounted:ro ghcr.io/u1f992/vivliostyle-slim:<tag> build
```

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

Re-slimming a derived image inherently means redoing the contract-driven derivation behind the vivliostyle-slim purge list itself (inlined in the `Dockerfile`). Offering something like a convenience script for re-slimming is impractical, but the vivliostyle-slim build process should serve as a valuable reference.

## Local build

Build a single-arch image into the local docker engine as `vivliostyle-slim:local`.

```shellsession
$ git clone https://github.com/vivliostyle/vivliostyle-cli
$ cd vivliostyle-cli
$ git checkout <cli-ref>   # the tag or sha you are packaging

$ git fetch https://github.com/vivliostyle/vivliostyle-cli pull/793/head
$ git checkout FETCH_HEAD -- Dockerfile build/adobe-notdef

$ docker buildx create --driver docker-container \
    --buildkitd-flags '--allow-insecure-entitlement security.insecure' --use
$ docker buildx build \
    --allow security.insecure \
    --build-arg VS_CLI_VERSION=$(jq -r .version package.json) \
    --build-arg BROWSER=chrome@$(sed -n '/START DEFAULT_BROWSER_VERSIONS/,/END DEFAULT_BROWSER_VERSIONS/p' src/constants.ts | grep -oP 'chrome:\s*\K\{[^}]+\}' | jq -r .linux) \
    --tag vivliostyle-slim:local --load .
```

The image contract is a vitest + testcontainers suite (`tests/docker-image.test.ts`, run via `pnpm test:docker`) that captures the behavior the upstream container and the slim container must implement alike. It is a black-box check driven entirely by `VIVLIOSTYLE_CLI_IMAGE`, so run it from the PR head, which carries the harness and its `testcontainers`/`vitest` devDependencies. `git checkout -f FETCH_HEAD` moves the same clone to that tree:

```shellsession
$ git checkout -f FETCH_HEAD
$ pnpm install
$ VIVLIOSTYLE_CLI_IMAGE=vivliostyle-slim:local pnpm test:docker
```

Its GUI preview tests open a headful browser against an Xvfb sidecar; set `VIVLIOSTYLE_CLI_ARTIFACT_DIR` to a directory to keep the test artifacts (a screenshot per browser and the built PDFs) to eyeball, since whether the window rendered correctly cannot be asserted mechanically.

show gui on host x server

linux

```shellsession
$ xhost
access control enabled, only authorized clients can connect
$ xhost +SI:localuser:$(id -un)
localuser:mukai being added to access control list
$ xhost
access control enabled, only authorized clients can connect
SI:localuser:mukai

$ docker run --rm --interactive --tty --env DISPLAY --user "$(id -u):$(id -g)" --volume /tmp/.X11-unix:/tmp/.X11-unix vivliostyle-slim:local preview

$ xhost -SI:localuser:$(id -un)
localuser:mukai being removed from access control list
$ xhost
access control enabled, only authorized clients can connect
```

over ssh

```shellsession
$ ssh -Y <user>@<host>

$ echo "$DISPLAY"
localhost:10.0
$ XAUTH=$(mktemp)
$ xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH" nmerge -
$ chmod 644 "$XAUTH"
$ docker run --rm --interactive --tty --network host --env DISPLAY --env XAUTHORITY=/tmp/.xauth --volume "$XAUTH:/tmp/.xauth:ro" vivliostyle-slim:local preview

$ rm -f "$XAUTH"
$ exit
```
