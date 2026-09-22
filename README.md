[![tests](https://github.com/penyaskito/ddev-hugo/actions/workflows/tests.yml/badge.svg)](https://github.com/ddev/ddev-hugo/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2026.svg)

# ddev-hugo <!-- omit in toc -->

- [What is ddev-hugo?](#what-is-ddev-hugo)
- [Getting started](#getting-started)
- [The `ddev hugo` command](#the-ddev-hugo-command)
- [Hugo version](#hugo-version)

## What is ddev-hugo?

This repository is a [DDEV](https://ddev.readthedocs.io) add-on for providing [Hugo](https://gohugo.io) support.

In DDEV addons can be installed from the command line using the `ddev add-on get` command, as in `ddev add-on get penyaskito/ddev-hugo`.

## Getting started

1. Create your ddev project with `ddev config --omit-containers=db --docroot public`
2. Run `ddev add-on get penyaskito/ddev-hugo`
3. Run `ddev hugo`
4. Run `ddev launch`

## The `ddev hugo` command

The add-on installs a `ddev hugo` command, so Hugo can be run directly rather
than through `ddev exec hugo`:

```bash
ddev hugo version
ddev hugo new site . --force
ddev hugo new content posts/hello.md
ddev hugo
```

Flags are passed straight through to Hugo, the command runs in the container
directory matching your current host directory, and generated files (such as
`public/`) are synced back to the host.

## The Hugo dev server

`ddev hugo server` starts Hugo's live-reload server and is reachable from the
host, on port 1313 over HTTPS and 1314 over HTTP:

```bash
ddev hugo server
```

`ddev describe` lists the URL under `hugo`. The command supplies `--bind`,
`--port`, `--baseURL` and `--appendPort` so the server listens on an address
the DDEV router can reach and generates links pointing at the routed URL.
Passing any of those flags yourself overrides the default, and setting
`HUGO_SERVER_PORT` changes the port the command uses.

Everything else is passed through, so the usual flags work:

```bash
ddev hugo server --buildDrafts --disableFastRender
```

## Hugo version

Hugo (extended edition) is installed from the [official releases](https://github.com/gohugoio/hugo/releases)
during the web container build. To use a different release, edit `HUGO_VERSION`
in `.ddev/web-build/Dockerfile.ddev-hugo` and run `ddev restart`.

Remove the `#ddev-generated` line at the top of that file to keep your changes
from being overwritten the next time you run `ddev add-on get`.

**Contributed and maintained by [@penyaskito](https://github.com/penyaskito)**
