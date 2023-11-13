#@PRIORITY: 8
#@DEPENDENCIES: bc

# This function safely changes directory and stops the full execution in case it failed
# arg0: The path of the directory we want to use
# Example:
#   utilities_safeCD "/tmp/mypath"
#   echo "I safely arrived into $PWD !"
function utilities_safeCD() {
  if [[ $# -eq 1 ]]; then
    if ! cd "$1" &>/dev/null; then
      bashlib_abort "$(caller)" "the folder $1 cannot be reached from the current one ($PWD)"
    fi
  else
    bashlib_abort "$(caller)" "[path]"
  fi
}

# This function trigger a sleep that can be interupted while the process is sleeping
# arg0: The time to sleep
# Note:
#   This can be useful when working with multiple processes as in bash a sleeping process will never trigger any trapped signal until the end of the sleep
function utilities_interruptableSleep() {
  if [[ $# -eq 1 ]]; then
    sleep "$1" &
    wait $!
  else
    bashlib_abort "$(caller)" "[time to sleep]"
  fi
}

# This function checks if a given ipv4 is following the proper format and is valid or not
# arg0: The ip to validate
# Example:
#   if utilities_validateIP 192.168.5.1; then
#     echo "The ip is valid !"
#   fi
function utilities_validateIP() {
  local __IS_IP_VALID__=1
  if [[ $# -eq 1 ]]; then
    if [[ "$1" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
      local oldIFS=$IFS
      local ip=()
      IFS="."
      # shellcheck disable=SC2206
      ip=($1)
      if [[ ${ip[0]} -le 255 ]] && [[ ${ip[1]} -le 255 ]] && [[ ${ip[2]} -le 255 ]] && [[ ${ip[3]} -le 255 ]]; then
        __IS_IP_VALID__=0
      fi
      IFS=$oldIFS
    fi
  else
    bashlib_abort "$(caller)" "[ip]"
  fi
  return $__IS_IP_VALID__
}

# This function checks between two given version number and returns 0 in case the available version is more up-to-date
# arg0: The current version
# arg1: The available version
# return: 0 if arg1 > arg0, 1 otherwise
# Note:
#   The 'version' should be a string following 'usual' versioning definition (e.g. main.minor.patch), any other character will be dropped (e.g. 'v' or 'rc')
function utilities_upgradeRequired() {
  if [[ $# -eq 2 ]]; then
    local __IS_UPGRADE_REQUIRED__=1
    local current="$((10#${1//[!0-9]/}))"
    local available="$((10#${2//[!0-9]/}))"
    local nCurrent="${1//[!\.]/}"
    local nAvailable="${2//[!\.]/}"
    if [[ ${#nCurrent} -lt ${#nAvailable} ]]; then
      current=$((current * 10 * $((${#nAvailable} - ${#nCurrent}))))
    elif [[ ${#nAvailable} -lt ${#nCurrent} ]]; then
      available=$((available * 10 * $((${#nCurrent} - ${#nAvailable}))))
    fi
    if [[ $((10#$available)) -gt $((10#$current)) ]]; then
      __IS_UPGRADE_REQUIRED__=0
    fi
  else
    bashlib_abort "$(caller)" "[current version] [available version]"
  fi
  return "$__IS_UPGRADE_REQUIRED__"
}

# This function uses bc to convert a given number of bytes into a readable string
# arg0: The number of bytes to convert
# arg1: The name of the variable that will contain the readable value with unit (string)
# Example:
#   utilities_bytesToReadable 53082459082 result
#   echo "Result: $res" # print '49.43 Gio'
#@DEPENDS: bc
function utilities_bytesToReadable() {
  if [[ $# -eq 2 ]]; then
    local bytes=$1
    local -n __READABLE_BYTES__=$2
    local index=0
    local unit=("o" "Kio" "Mio" "Gio" "Tio" "Pio")
    while [[ $(bc <<< "$bytes > 1024") -eq 1 ]]; do
      bytes=$(bc <<< "scale=2; $bytes / 1024")
      index=$((++index))
    done
    __READABLE_BYTES__="$bytes ${unit[$index]}"
  else
    bashlib_abort "$(caller)" "[bytes] [&result]"
  fi
}
