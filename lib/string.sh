
function string_toUpperCase() {
  if [[ $# -eq 2 ]]; then
    local -n __UPPER_CASE_STR__=$2
    __UPPER_CASE_STR__=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  else
    false
  fi
}

function string_toLowerCase() {
  if [[ $# -eq 2 ]]; then
    local -n __LOWER_CASE_STR__=$2
    __LOWER_CASE_STR__=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  else
    false
  fi
}

# This function trim leading/trailing/all whitespaces from a string
# arg0: The string to trim
# arg1: The type of whitespace we want to remove ('leading', 'trailing' or 'all')
# arg2: The name of the variable that will contain the trimmed string
# Example:
#   str=" string with spaces "
#   string_trim str "leading" str0
#   string_trim str "trailing" str1
#   string_trim str "all" str2
#   echo "String without leading whitespaces: [$str0]"
#   echo "String without trailing whitespaces: [$str1]"
#   echo "String without any whitespaces: [$str2]"
function string_trim() {
  if [[ $# -eq 3 ]]; then
    local -n __TRIMMED_STR__=$3
    case "$2" in
      leading) __TRIMMED_STR__=$(echo -e "$1" | sed -e 's/^[[:space:]]*//');;
      trailing) __TRIMMED_STR__=$(echo -e "$1" | sed -e 's/[[:space:]]*$//');;
      all) __TRIMMED_STR__=$(echo -e "$1" | tr -d '[:space:]');;
      *) false;;
    esac
  else
    false
  fi
}
