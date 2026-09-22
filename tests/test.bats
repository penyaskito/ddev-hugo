#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  export GITHUB_REPO=penyaskito/ddev-hugo

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  export TESTDIR="${HOME}/tmp/${PROJNAME}"
  mkdir -p "${TESTDIR}"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site --omit-containers=db --docroot=public
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # The add-on must provide the extended edition, which is what supports
  # Sass/SCSS and WebP processing.
  run ddev hugo version
  assert_success
  assert_output --partial "extended"

  # The command must take flags without ddev consuming them, which is what
  # ExecRaw buys us.
  run ddev hugo new site quickstart --force
  assert_success
  mv quickstart/* .
  rm -rf quickstart
  run ddev hugo new theme testtheme
  assert_success
  echo "theme = 'testtheme'" >> hugo.toml
  # The generated theme renders the home page content, so no layout tweak is needed.
  printf "+++\ntitle = 'Home'\n+++\n\n# Welcome to Hugo!\n" > content/_index.md
  run ddev hugo
  assert_success

  # Output must reach the host, not just the container, so MutagenSync matters.
  assert_file_exists public/index.html
  run curl -s "$(ddev describe -j | jq -r .raw.primary_url)/index.html"
  assert_success
  assert_output --partial "Welcome to Hugo"
}

server_checks() {
  # hugo server must be reachable from the host, which needs both a routed
  # 1313 and a bind address other than 127.0.0.1.
  # Strip any router port off the primary URL before adding Hugo's.
  local url
  url="$(ddev describe -j | jq -r .raw.primary_url | sed -E 's#(https?://[^/:]+).*#\1#'):1313"

  # The routed port must be advertised, so `ddev describe` can show it.
  run ddev describe
  assert_success
  assert_output --partial "${url}"

  nohup ddev hugo server >"${TESTDIR}/hugo-server.log" 2>&1 &
  local server_pid=$!

  # Retry rather than sleep; the server and the router each need a moment, and
  # the router answers 502 until the backend is up. Ask for "/" because Hugo
  # redirects /index.html to it.
  local body=""
  local i
  for i in $(seq 1 30); do
    body="$(curl -s --max-time 3 "${url}/")" || true
    case "${body}" in
      *"Welcome to Hugo"*) break ;;
    esac
    body=""
    sleep 1
  done

  kill "${server_pid}" >/dev/null 2>&1 || true
  ddev exec pkill hugo >/dev/null 2>&1 || true

  assert [ -n "${body}" ]
  # A server bound to 127.0.0.1 answers inside the container but not from here,
  # so assert the address and URL Hugo reported as well.
  run grep -F "bind address 0.0.0.0" "${TESTDIR}/hugo-server.log"
  assert_success
  run grep -F "${url}" "${TESTDIR}/hugo-server.log"
  assert_success
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
  server_checks
}

# This installs the latest published release rather than the working tree.
# .github/workflows/tests.yml uses the tag to run it as a separate job.
# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
  server_checks
}
