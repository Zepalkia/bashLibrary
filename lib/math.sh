#@PRIORITY: 2

# This function returns the max value between two given values, for arrays look for 'array_argmax'
# arg0: The first value to compare (integer)
# arg1: The second value to compare (integer)
# arg2: The name of the variable that will contain the max value
# Example:
#   math_max 5 10 result
#   echo "The max value is: $result"
function math_max() {
  if [[ $# -eq 3 ]]; then
    local -n __MAXIMUM_VALUE__=$3
    if [[ $1 -gt $2 ]]; then
      __MAXIMUM_VALUE__=$1
    else
      __MAXIMUM_VALUE__=$2
    fi
  else
    bashlib_abort "$(caller)" "$FUNCNAME" "[value 1] [value 2] [&result]"
  fi
}

# This function returns the min value between two given values, for arrays look for 'array_argmin'
# arg0: The first value to compare (integer)
# arg1: The second value to compare (integer)
# arg2: The name of the variable that will contain the min value
# Example:
#   math_max 5 10 result
#   echo "The min value is: $result"
function math_min() {
  if [[ $# -eq 3 ]]; then
    local -n __MINIMUM_VALUE__=$3
    if [[ $1 -lt $2 ]]; then
      __MINIMUM_VALUE__=$1
    else
      __MINIMUM_VALUE__=$2
    fi
  else
    bashlib_abort "$(caller)" "$FUNCNAME" "[value 1] [value 2] [&result]"
  fi
}
