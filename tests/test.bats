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
  ddev exec hugo version | grep extended
  ddev exec hugo new site quickstart
  mv quickstart/* .
  rm -rf quickstart
  ddev exec hugo new theme testtheme
  echo "theme = 'testtheme'" >> hugo.toml
  # The generated theme renders the home page content, so no layout tweak is needed.
  printf "+++\ntitle = 'Home'\n+++\n\n# Welcome to Hugo!\n" > content/_index.md
  ddev exec hugo
  ddev exec "curl -s https://localhost/index.html" | grep "Welcome to Hugo"
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

