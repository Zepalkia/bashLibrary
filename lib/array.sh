
# This function search for the min element in an array of integer, returning both the found value and the index inside the array
# arg0: The NAME of the array variable (not the array values)
# arg1: The name of the variable that will contain the 'max' value
# arg2: The name of the variable that will contain the 'argmax' index value
# Example:
#   array=(2 5 4 3 0)
#   array_argmax array max argmax
#   echo "The max value $max of the array is stored at index $argmax"
# Note:
#  The index of the first occurence will be returned in case of multiple min values
function array_argmax() {
  if [[ $# -eq 3 ]] && [[ "$(declare -p $1)" =~ "declare -a" ]]; then
    local -n __MAXIMUM_VALUE__=$2
    local -n __ARGMAX_VALUE__=$3
    local mathArray=$1[@]
    local count=0
    local temporaryValue=""
    for value in "${!mathArray}"; do
      if [[ "$temporaryValue" == "" ]]; then
        temporaryValue=$value
        __ARGMAX_VALUE__=0
      elif [[ $temporaryValue -lt $value ]]; then
        temporaryValue=$value
        __ARGMAX_VALUE__=$count
      fi
      count=$((++count))
    done
    __MAXIMUM_VALUE__=$temporaryValue
  else
    false
  fi
}


function array_argmin() {
  if [[ $# -eq 3 ]] && [[ "$(declare -p $1)" =~ "declare -a" ]]; then
    local -n __MINIMUM_VALUE__=$2
    local -n __ARGMIN_VALUE__=$3
    local mathArray=$1[@]
    local count=0
    local temporaryValue=""
    for value in "${!mathArray}"; do
      if [[ "$temporaryValue" == "" ]]; then
        temporaryValue=$value
        __ARGMIN_VALUE__=0
      elif [[ $temporaryValue -gt $value ]]; then
        temporaryValue=$value
        __ARGMIN_VALUE__=$count
      fi
      count=$((++count))
    done
    __MINIMUM_VALUE__=$temporaryValue
  else
    false
  fi
}
