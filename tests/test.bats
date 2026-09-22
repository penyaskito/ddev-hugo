setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-hugo
  mkdir -p $TESTDIR
  export PROJNAME=test-hugo
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME} --omit-containers=db --docroot=public
  ddev start -y >/dev/null
}

health_checks() {
  # The add-on must provide the extended edition, which is what supports
  # Sass/SCSS and WebP processing.
  ddev hugo version | grep extended
  # The command must take flags without ddev consuming them, which is what
  # ExecRaw buys us.
  ddev hugo new site quickstart --force
  mv quickstart/* .
  rm -rf quickstart
  ddev hugo new theme testtheme
  echo "theme = 'testtheme'" >> hugo.toml
  # The generated theme renders the home page content, so no layout tweak is needed.
  printf "+++\ntitle = 'Home'\n+++\n\n# Welcome to Hugo!\n" > content/_index.md
  ddev hugo
  # Output must reach the host, not just the container, so MutagenSync matters.
  [ -f public/index.html ]
  curl -s "$(ddev describe -j | jq -r .raw.primary_url)/index.html" | grep "Welcome to Hugo"
}

teardown() {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install from directory" {
  set -eu -o pipefail
  cd ${TESTDIR}
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get ${DIR}
  ddev restart
  health_checks
}

# This installs the latest published release rather than the working tree.
# .github/workflows/tests.yml uses the tag to run it as a separate job.
# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev add-on get penyaskito/ddev-hugo with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev add-on get penyaskito/ddev-hugo
  ddev restart >/dev/null
  health_checks
}

