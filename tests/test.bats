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

server_checks() {
  # hugo server must be reachable from the host, which needs both a routed
  # 1313 and a bind address other than 127.0.0.1.
  # Strip any router port off the primary URL before adding Hugo's.
  local url
  url="$(ddev describe -j | jq -r .raw.primary_url | sed -E 's#(https?://[^/:]+).*#\1#'):1313"

  # The routed port must be advertised, so `ddev describe` can show it.
  ddev describe | grep -F "${url}"

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

  [ -n "${body}" ]
  # A server bound to 127.0.0.1 answers inside the container but not from here,
  # so assert the address and URL Hugo reported as well.
  grep -q "bind address 0.0.0.0" "${TESTDIR}/hugo-server.log"
  grep -qF "${url}" "${TESTDIR}/hugo-server.log"
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
  server_checks
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
  server_checks
}

