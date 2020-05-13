#@DEPENDENCIES: bc

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

