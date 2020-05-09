function signals_ctrlC() {
  __ctrlC__
}

function signals_hangup() {
  touch /tmp/.sighup
  bg
}

function signals_reattach() {
  __hangup__
  rm /tmp/.sighup
}

function signals_init() {
  if [[ "$(type -t __ctrlC__)" == "function" ]]; then
    trap signals_ctrlC SIGINT
  fi
  if [[ "$(type -t __hangup__)" == "function" ]]; then
    trap signals_hangup SIGHUP
  fi
}
