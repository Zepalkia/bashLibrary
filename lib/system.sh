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

# This function checks if a given package is installed on the system using dpkg
# arg0: The name of the package to look for
# arg1: The name of the variable that will contain the answer (boolean)
# Example:
#   system_packageInstalled "git" result
#   [[ $result == true ]] && echo "Git is installed on the system !"
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

# This function retrieves the sorted (by space used) list of all the packages currently installed on the system
# arg0: The name of the variable that will contain the list (array)
# Example:
#   system_listPackages array
#   echo "The biggest package installed on the system is: ${array[0]}"
function system_listPackages() {
  if [[ $# -eq 1 ]]; then
    local -n __PACKAGE_ARRAY__=$1
    mapfile -t __PACKAGE_ARRAY__ < <(dpkg-query -W --showformat='${Installed-Size;10}\t${Package}\n' | sort -k1,1nr)
  else
    false
  fi
}
