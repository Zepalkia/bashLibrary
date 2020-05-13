# This function checks if a given command exists or not in the system, this can be used as a way of checking if a package is installed or not and offers the
# expecting command-line functionalities
# arg0: The command that should be available on the system
# arg1: The name of the variable that will contain the result (boolean)
# Example:
#   system_commandExists "bash" result
#   [[ $result == true ]] && echo "Good news, bash is installed on your system !"
function system_commandExists() {
  if [[ $# -eq 2 ]]; then
    local -n __COMMAND_DOES_EXISTS__=$2
    if command -v "$1" &>/dev/null; then
      __COMMAND_DOES_EXISTS__=true
    else
      __COMMAND_DOES_EXISTS__=false
    fi
  else
    false
  fi
}

function system_packageInstalled() {
  if [[ $# -eq 2 ]]; then
    local -n __PACKAGE_IS_INSTALLED__=$2
    if dpkg -s "$1" &>/dev/null; then
      __PACKAGE_IS_INSTALLED__=true
    else
      __PACKAGE_IS_INSTALLED__=false
    fi
  else
    false
  fi
}
