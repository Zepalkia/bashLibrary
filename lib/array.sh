# This function search for the max element in an array of integer, returning both the found value and the index inside the array
# arg0: The NAME of the array variable (not the array values)
# arg1: The name of the variable that will contain the 'max' value
# arg2: The name of the variable that will contain the 'argmax' index value
# Example:
#   array=(2 5 4 3 0)
#   array_argmax array max argmax
#   echo "The max value $max of the array is stored at index $argmax"
# Note:
#  The index of the first occurence will be returned in case of multiple max values
function array_argmax() {
  if [[ $# -eq 3 ]] && [[ $(declare -p 2>/dev/null | grep "$1" | grep -c "declare -a") -gt 0 ]]; then
    local -n __MAXIMUM_VALUE__=$2
    local -n __ARGMAX_VALUE__=$3
    local mathArray="$1[@]"
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
    bashlib_abort "$(caller)" "[&array] [&result0 (max)] [&result1 (argmax)]"
  fi
}


# This function search for the min element in an array of integer, returning both the found value and the index inside the array
# arg0: The NAME of the array variable (not the array values)
# arg1: The name of the variable that will contain the 'min' value
# arg2: The name of the variable that will contain the 'argmin' index value
# Example:
#   array=(2 5 4 3 0)
#   array_argmin array min argmin
#   echo "The min value $min of the array is stored at index $argmin"
# Note:
#  The index of the first occurence will be returned in case of multiple min values
function array_argmin() {
  if [[ $# -eq 3 ]] && [[ $(declare -p 2>/dev/null | grep "$1" | grep -c "declare -a") -gt 0 ]]; then
    local -n __MINIMUM_VALUE__=$2
    local -n __ARGMIN_VALUE__=$3
    local mathArray="$1[@]"
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
    bashlib_abort "$(caller)" "[&array] [&result0 (min)] [&result1 (argmin)]"
  fi
}

# This function inserts a new element into an array at a specific position
# arg0: The name of the variable containing the array to modify
# arg1: The position in which to add the new element (0-based)
# arg2: The element to add into the array
function array_insert() {
  if [[ $# -eq 3 ]]; then
    local -n __ARRAY_WITH_INSERTION__=$1
    if [[ $2 -ge ${#__ARRAY_WITH_INSERTION__[@]} ]]; then
      __ARRAY_WITH_INSERTION__+=("$3")
    else
      __ARRAY_WITH_INSERTION__=("${__ARRAY_WITH_INSERTION__[@]:0:$2}" "$3" "${__ARRAY_WITH_INSERTION__[@]:$2}")
    fi
  else
    bashlib_abort "$(caller)" "[&array] [position] [element]"
  fi
}
