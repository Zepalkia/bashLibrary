function signals_hSIGINT() {
  __hSIGINT__
}

function signals_hSIGHUP() {
  touch /tmp/.sighup
  bg
}

function signals_reattach() {
  __hSIGHUP__
  rm /tmp/.sighup
}

function signals_hSIGWINCH() {
  __hSIGWINCH__
}

# This function sets the user-defined trap function of some useful signals, the following signals are ready to be handled:
# SIGINT (if a function '__hSIGINT__' exists):
#   Every time such a signal (e.g. send by CTRL+C) is raised this function will be called with nothing else done (so the application will not exit by itself,
#   is has to be defined in the user function)
# SIGHUP (if a function '__hSIGHUP__' exists):
#  Every time such a signal (e.g. if a remote connection is lost for some time) is raised the script will be sent to background to continue working despite the
#  loss of the terminal and a '.sighup' file will be generated inside /tmp. It's up to the user to detect this file and calling 'signals_reattach' to trigger
#   the __hSIGHUP__ function and the removal of the .sighup file
# SIGWINCH (if a function '__hSIGWINCH__' exists):
#   Every time such a signal (terminal resize) is raised, this function will be called
function signals_init() {
  if [[ "$(type -t __ctrlC__)" == "function" ]]; then
    trap signals_hSIGINT SIGINT
  fi
  if [[ "$(type -t __hangup__)" == "function" ]]; then
    trap signals_hSIGHUP SIGHUP
  fi
  if [[ "$(type -t __resize__)" == "function" ]]; then
    trap signals_hSIGWINCH SIGWINCH
  fi
}

function signals_reset() {
  local signals=(SIGINT SIGHUP SIGWINCH)
  for signal in ${signals[@]}; do
    trap - $signal
  done
}
