#@PRIORITY: 3
#@DEPENDENCIES: bc

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
    bashlib_abort "$(caller)" "[value 1] [value 2] [&result]"
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
    bashlib_abort "$(caller)" "[value 1] [value 2] [&result]"
  fi
}

# This function generates a linear space of points in a [min, max] interval
# arg0: The name of the variable (array) that will contain the points
# arg1: The min value
# arg2: The max value
# arg3: The number of point to generates
# Note:
#   The generated points will not be usable directly by bash as they will be decimal values; use bc or another higher-level
#   language/process like octave or gnuplot (see 'plot.sh' functions) to handle these points
#@DEPENDS: bc
function math_linspace() {
  if [[ $# -eq 4 ]]; then
    local dist=0 range=0
    local -n __LINSPACE_ARRAY__=$1
    range="$(echo "$3 - $2" | bc -l)"
    dist="$(echo "${range#-} / $4" | bc -l)"
    __LINSPACE_ARRAY__=()
    for ((i = 0; i < $4; ++i)); do
      __LINSPACE_ARRAY__+=("$(echo "$dist * $i" | bc -l)")
    done
  else
    bashlib_abort "$(caller)" "[&array] [start] [end] [nPoints]"
  fi
}
