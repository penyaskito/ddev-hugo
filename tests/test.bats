setup() {
  set -eu -o pipefail
  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export TESTDIR=~/tmp/test-hugo
  mkdir -p $TESTDIR
  export PROJNAME=test-hugo
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  ddev config --project-name=${PROJNAME} --omit-containers=db
  ddev start -y >/dev/null
}

health_checks() {
  # Do something useful here that verifies the add-on
  # ddev exec "curl -s elasticsearch:9200" | grep "${PROJNAME}-elasticsearch"
  ddev exec hugo new site quickstart
  mv quickstart/* .
  rm -rf quickstart
  ddev exec hugo new theme testtheme
  echo "{{.Site.Home.Content}}" >> themes/testtheme/layouts/index.html
  echo "theme = 'testtheme'" >> config.toml
  ddev exec hugo new _index.md
  echo "# Welcome to Hugo!" >> content/_index.md
  # Remove draft:true with sed
  sed -i '4d' content/_index.md
  ddev exec hugo -b public
  ddev exec "curl -s https://localhost/public/index.html" | grep "Welcome to Hugo"
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
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR}
  ddev restart
  health_checks
}

@test "install from release" {
  set -eu -o pipefail
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  echo "# ddev get ddev/ddev-hugo with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get penyaskito/ddev-hugo
  ddev restart >/dev/null
  health_checks
}

