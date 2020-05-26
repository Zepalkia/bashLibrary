# This function checks if a given command exists or not in the system, this can be used as a way of checking if a package is installed or not and offers the
# expecting command-line functionalities
# arg0: The command that should be available on the system
# Example:
#   if system_commandExists bash; then
#     echo "Good news, bash is installed on your system !"
#   fi
function system_commandExists() {
  local __COMMAND_DOES_EXISTS__=1
  if [[ $# -eq 1 ]]; then
    if command -v "$1" &>/dev/null; then
      __COMMAND_DOES_EXISTS__=0
    fi
  else
    false
  fi
  return $__COMMAND_DOES_EXISTS__
}

# This function checks if a given package is installed on the system using dpkg
# arg0: The name of the package to look for
# Example:
#   if system_packageInstalled "git"; then
#     echo "Git is installed on the system !"
#   fi
function system_packageInstalled() {
  local __PACKAGE_IS_INSTALLED__=1
  if [[ $# -eq 1 ]]; then
    if dpkg -s "$1" &>/dev/null; then
      __PACKAGE_IS_INSTALLED__=0
    fi
  else
    false
  fi
  return $__PACKAGE_IS_INSTALLED__
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
