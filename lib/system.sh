#@PRIORITY: 0
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
    bashlib_abort "$(caller)" "[command]"
  fi
  return $__COMMAND_DOES_EXISTS__
}

# This function checks if all the commands given in an array exists in one single call
# arg0: The name of the array containing all the commands to check
# arg1: The name of the variable that will contain the name of the FIRST missing command
# return: 0 if all the commands exists, 1 otherwise
# Example:
#   commands=("zip" "ls" "bash")
#   if ! system_commandsExists commands result; then
#     echo "Missing command: $result"
#   fi
function system_commandsExists() {
  local __COMMANDS_ALL_FOUND__=0
  local -n __MISSING_COMMAND__=$2
  local cmdArray="$1[@]"
  if [[ $# -eq 2 ]]; then
    for cmd in "${!cmdArray}"; do
      if ! system_commandExists "$cmd"; then
        __COMMANDS_ALL_FOUND__=1
        __MISSING_COMMAND__="$cmd"
        break
      fi
    done
  else
    bashlib_abort "$(caller)" "[array of commands] [&first non existing command (if any)]"
  fi
  return $__COMMANDS_ALL_FOUND__
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
    bashlib_abort "$(caller)" "[package]"
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
    bashlib_abort "$(caller)" "[&result]"
  fi
}

# This function will create and activate inside the system a new swap file of a given size. By default /swapfile will be used but an optional path can be given
# to define another swap file location.
# arg0: The number of MEGABYTES of swap to create (be careful here to have enough space on the partition, this has to be checked BEFORE calling this function)
# arg1: The (optional) path where the file will be created, by default /swapfile is used
# return: 0 if the swap creation was successful, 1 otherwise
# Example:
#   if system_createSwap 4000; then
#     echo "My system has now 4Go of SWAP !"
#   fi
# Note:
#   This function has to be run as root, you need to have the right to create file in / and to create and enable the swap file, this is moreover not permanent !
#   The swapfile will still be there after a reboot but not loaded automatically by the system, to make it permanent you have to add it as well into your
# /etc/fstab file but be VERY VERY CAREFUL because playing with this file could potentially break completely your system
function system_createSwap() {
  local __SWAP_CREATED__=1
  if [[ $# -ge 1 ]]; then
    if [[ $EUID -eq 0 ]]; then
      local swapFile="/swapfile"
      if [[ $# -eq 2 ]]; then
        swapFile="$2"
      fi
      if swapoff -a &>/dev/null; then
        rm -f "$swapFile"
        dd if=/dev/zero of="$swapFile" bs=1M count="$1" &>/dev/null
        chmod 0600 "$swapFile" &>/dev/null
        mkswap "$swapFile" &>/dev/null
        if swapon "$swapFile"; then
          __SWAP_CREATED__=0
        fi
      fi
    else
      bashlib_abort "$(caller)" "must be run as root"
    fi
  else
    bashlib_abort "$(caller)" "[Number of swap Mo to create] {path to swap file}"
  fi
  return $__SWAP_CREATED__
}

# This function forces the system to empty the SWAP completely before re-enabling it effectively cleaning it completely. Be aware that this should technically
# never be used except in very specific situations where the system is bloated and really require such operation.
# This function will moreover take potentially lots of time (depending on your swap&ram size and your memory speed) and will flush the entire swap into the ram.
# Doing this will 'force' the system to release unwanted memory leftovers and to reorganize the ram usage (but again, this should technically never be useful in
# an healthy system using properly developped applications)
# arg0: The path to the swapfile (optional), if not given the function will automatically clear the swap partition instead
# return: 0 if the swap has been cleared properly, 1 otherwise
function system_clearSwap() {
  local __SWAP_CLEARED__=1
  if [[ $EUID -eq 0 ]]; then
    if [[ $# -eq 1 ]] && [[ -f "$1" ]]; then
      if swapoff -a &>/dev/null; then
        if swapon "$1"; then
          __SWAP_CLEARED__=0
        fi
      fi
    elif [[ $# -eq 0 ]]; then
      if swapoff -a &>/dev/null; then
        if swapon -a; then
          __SWAP_CLEARED__=0
        fi
      fi
    else
      __SWAP_CLEARED__=2
    fi
  else
    bashlib_abort "$(caller)" "must be run as root"
  fi
  return $__SWAP_CLEARED__
}

# This function launch an already-declared function as root using 'sudo' utility
# arg0: The name of the function to launch as root
# arg1: The name of the variable that will contain the value returned by the function
# arg2: (optional) A string of all the arguments to pass to the function
# Note:
#   The process will catch any output and write it inside the /tmp/.dump file in case it's required to check some output data
function system_asRoot() {
  if [[ $# -ge 2 ]] && [[ "$(type -t "$1")" == "function" ]]; then
    local -n __AS_ROOT_RESULT__=$2
    sudo bash -c "$(declare -f "$1"); $1 $3 &>/tmp/.dump"
    __AS_ROOT_RESULT__=$?
  else
    bashlib_abort "$(caller)" "[function name] [&result] {arguments}"
  fi
}

# This function returns the number of cores fully in used by the system
# arg0: The name of the variable that will contain the result value
# Note:
#   The result is obviously an approximation done in a single snapshot of the system, moreover it only takes into account 1 core = 100% without ceiling the
#   percentage value, to be used only to have a global view of the processor status at time T (e.g. if you want to know how much cores are free to be used by
#   a background process)
function system_coresInUse() {
  if [[ $# -eq 1 ]]; then
    local -n __CORES_IN_USE__=$1
    local percentage=0
    percentage=$(top -b -n 1 | head -20 | awk '{print $9}' | tail -13 | paste -sd+ | bc)
    __CORES_IN_USE__=$((${percentage%.*} / 100))
  else
    bashlib_abort "$(caller)" "[&result]"
  fi
}

# This function checks if a given process (pid) is running on the system
# arg0: The PID of the process to check
# return: 0 if the process is running, 1 otherwise
# Example:
#   sudo sleep 60 &
#   while system_isProcessRunning "$1"; do
#     # Do stuff during 1 minute
#   done
function system_isProcessRunning() {
  local processIsRunning=0
  if [[ $# -eq 1 ]]; then
    ps -p "$1" &>/dev/null
    processIsRunning=$?
  else
    bashlib_abort "$(caller)" "[PID]"
  fi
  return $processIsRunning
}

# This function checks if a given process (pid) is killable by the running instance
# arg0: The PID of the process to check
# return: 0 if the process is killable, 1 otherwise
# Example:
#   sudo sleep 60 &
#   if ! system_isProcessKillable "$!"; then
#      echo "The process has been launched as root, I cannot kill it !"
#   fi
function system_isProcessKillable() {
  local processIsKillable=0
  if [[ $# -eq 1 ]]; then
    kill -0 "$1" &>/dev/null
    processIsKillable=$?
  else
    bashlib_abort "$(caller)" "[PID]"
  fi
  return $processIsKillable
}

# This function grabs a snapshot of the current /proc/meminfo values and return the ram/swap info inside a map (values will be in kB)
# arg0: The name of the variable that will contain the result (will be cleaned and redeclared with -A)
function system_getMemoryInfo() {
  if [[ $# -eq 1 ]]; then
    local meminfo=""
    local -n __MEMINFOS__="$1"
    unset "$1"
    declare -gA "$1"
    meminfo=$(< /proc/meminfo)
    __MEMINFOS__["ram_total"]=$(echo "$meminfo" | grep "MemTotal" | awk '{print $2}')
    __MEMINFOS__["ram_free"]=$(echo "$meminfo" | grep "MemFree" | awk '{print $2}')
    __MEMINFOS__["ram_available"]=$(echo "$meminfo" | grep "MemAvailable" | awk '{print $2}')
    __MEMINFOS__["swap_total"]=$(echo "$meminfo" | grep "SwapTotal" | awk '{print $2}')
    __MEMINFOS__["swap_free"]=$(echo "$meminfo" | grep "SwapFree" | awk '{print $2}')
  else
    bashlib_abort "$(caller)" "[&result]"
  fi
}
