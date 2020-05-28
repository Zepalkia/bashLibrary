#@DEPENDENCIES: bc

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

