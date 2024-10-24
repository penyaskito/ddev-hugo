[![tests](https://github.com/penyaskito/ddev-hugo/actions/workflows/tests.yml/badge.svg)](https://github.com/ddev/ddev-hugo/actions/workflows/tests.yml) ![project is maintained](https://img.shields.io/maintenance/yes/2024.svg)

# ddev-hugo <!-- omit in toc -->

- [What is ddev-hugo?](#what-is-ddev-hugo)
- [Getting started](#getting-started)

## What is ddev-hugo?

This repository is a [DDEV](https://ddev.readthedocs.io) add-on for providing [Hugo](https://gohugo.io) support.

In DDEV addons can be installed from the command line using the `ddev add-on get` command, as in `ddev add-on get ddev/ddev-hugo`.

## Getting started

1. Create your ddev project with `ddev config --omit-containers=db --docroot public`
2. Run `ddev add-on get https://github.com/penyaskito/ddev-hugo` (or `ddev get https://github.com/penyaskito/ddev-hugo` if your version of DDEV is older than 1.23.5)
3. Run `ddev exec hugo`
4. Run `ddev launch`

**Contributed and maintained by [@penyaskito](https://github.com/penyaskito)**
