#@DEPENDENCIES: bc

function utilities_validateIP() {
  if [[ $# -eq 2 ]]; then
    local -n __IS_IP_VALID__=$2
    __IS_IP_VALID__=false
    if [[ "$1" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
      local oldIFS=$IFS
      local ip=()
      IFS="."
      ip=($1)
      if [[ ${ip[0]} -le 255 ]] && [[ ${ip[1]} -le 255 ]] && [[ ${ip[2]} -le 255 ]] && [[ ${ip[3]} -le 255 ]]; then
        __IS_IP_VALID__=true
      fi
      IFS=$oldIFS
    fi
  else
    false
  fi
}

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
    false
  fi
}

