#@DEPENDENCIES: bc

# This function tokenize a string using a given delimiter and store the tokens into an array
# arg0: The string to tokenize
# arg1: The delimiter
# arg2: The name of the variable that will contain the final result (will be an array)
# Example:
#   utilities_stringTokenize "I;AM;ERROR" ";" array
#   echo "My name is: ${array[2]}"
function utilities_stringTokenize() {
  if [[ $# -eq 3 ]]; then
    local string="$1$2"
    local -n __TOKENIZED_STRING__=$3
    __TOKENIZED_STRING__=()
    while [[ $string ]]; do
      __TOKENIZED_STRING__+=("${string%%"$2"*}")
      string=${string#*"$2"}
    done
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

