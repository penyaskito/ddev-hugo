[![tests](https://github.com/penyaskito/ddev-hugo/actions/workflows/tests.yml/badge.svg)](https://github.com/ddev/ddev-hugo/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2024.svg)

# ddev-hugo <!-- omit in toc -->

* [What is ddev-hugo?](#what-is-ddev-hugo)
* [Components of the repository](#components-of-the-repository)
* [Getting started](#getting-started)
* [How to debug in Github Actions](#how-to-debug-tests-github-actions)

## What is ddev-hugo?

This repository is a [DDEV](https://ddev.readthedocs.io) add-on for providing [Hugo](https://gohugo.io) support.

In DDEV addons can be installed from the command line using the `ddev get` command, as in `ddev get ddev/ddev-hugo`.

## Getting started

1. Create your ddev project with `ddev config --omit-containers=db`
2. Run `ddev get https://github.com/penyaskito/ddev-hugo/tarball/main`
3. Run `ddev hugo`
4. Run `ddev launch hugo`

**Contributed and maintained by [@penyaskito](https://github.com/penyaskito)**
