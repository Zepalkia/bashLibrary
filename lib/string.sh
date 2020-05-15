#@PRIORITY: 7

# This function transforms a string by making all its chars in upper case
# arg0: The string to convert to upper case
# arg1: The name of the variable that will contain the upper-case string
# Example:
#   string_toUpperCase "TeSt" result
#   echo "Result: $result"
function string_toUpperCase() {
  if [[ $# -eq 2 ]]; then
    local -n __UPPER_CASE_STR__=$2
    __UPPER_CASE_STR__=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  else
    false
  fi
}

# This function transforms a string by making all its chars in lower case
# arg0: The string to convert to lower case
# arg1: The name of the variable that will contain the upper-case string
# Example:
#   string_toLowerCase "TeSt" result
#   echo "Result: $result"
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

# This function tokenize a string using a given delimiter and store the tokens into an array
# arg0: The string to tokenize
# arg1: The delimiter
# arg2: The name of the variable that will contain the final result (will be an array)
# Example:
#   string_tokenize "I;AM;ERROR" ";" array
#   echo "My name is: ${array[2]}"
function string_tokenize() {
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

# This function extracts a specific substring range from a given string
# arg0: The main string
# arg1: The substring starting position (0-indexed)
# arg2: The size of the substring
# arg3: The name of the variable that will contain the final result (will be a string)
# Example:
#   string_substr "abcdefghijklmnopqrstuvwxyz" 5 10 result
#   echo "$result"
function string_substr() {
  if [[ $# -eq 4 ]]; then
    local -n __RESULT_SUBSTRING__=$4
    __RESULT_SUBSTRING__=${1:$2:$3}
  else
    false
  fi
}

# This function returns the character at a specific position from a given string
# arg0: The main string
# arg1: The position (0-indexed) of the char
# arg2: The name of the variable that will contain the final result (will be a 1-char string)
# Example:
#   string_charAt "abcdef" 2 result
#   echo "Char at position 2: $result"
function string_charAt() {
  if [[ $# -eq 3 ]]; then
    local result=""
    local -n __CHAR_AT__=$3
    string_substr $1 $2 1 __CHAR_AT__
  else
    false
  fi
}
