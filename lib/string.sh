#@PRIORITY: 1
source variables.sh

# This function transforms a string by making all its chars in upper case
# arg0: The string to convert to upper case
# arg1: The name of the variable that will contain the upper-case string
# Example:
#   string_toUpperCase "TeSt" result
#   echo "Result: $result"
function string_toUpperCase() {
  if [[ $# -eq 2 ]]; then
    local -n __UPPER_CASE_STR__=$2
    __UPPER_CASE_STR__=${1^^}
  else
    bashlib_abort "$(caller)" "[string to convert] [&result]"
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
    __LOWER_CASE_STR__=${1,,}
  else
    bashlib_abort "$(caller)" "[string to convert] [&result]"
  fi
}

# This function trim leading/trailing/all whitespaces from a string
# arg0: The string to trim
# arg1: The type of whitespace we want to remove ('leading', 'trailing' or 'all')
# arg2: The name of the variable that will contain the trimmed string
# Example:
#   str=" string with spaces "
#   string_trim "$str" "leading" str0
#   string_trim "$str" "trailing" str1
#   string_trim "$str" "all" str2
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
    echo "[$1][$2][$3][$4][$5][$6][$7]"
    bashlib_abort "$(caller)" "[string to trim] [leading/trailing/all] [&result]"
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
    bashlib_abort "$(caller)" "[string to tokenize] [delimiter] [&result]"
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
    bashlib_abort "$(caller)" "[string] [substring starting position] [substring size] [&result]"
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
    string_substr "$1" "$2" 1 __CHAR_AT__
  else
    bashlib_abort "$(caller)" "[string] [position] [&result]"
  fi
}

# This function generates as fixed-size random string containing a given subset of characters
# arg0: The charset available (You can specify range like 'a-z', be aware that specific characters will have to be escaped, e.g. "\\\\" to have "\")
# arg1: The length of the final randomized string
# arg2: The name of the variable that will contain the result (a string)
# Example:
#   string_rand "0-9" 100 result
#   echo "Here's a random 100-digit number: $result"
function string_rand() {
  if [[ $# -eq 3 ]]; then
    local -n __RANDOM_STRING__=$3
    __RANDOM_STRING__=$(</dev/urandom tr -dc "$1" | head -c "$2")
  else
    bashlib_abort "$(caller)" "[charset] [length] [&result]"
  fi
}

# This function transforms a 'rich' encoded string and returns it ready to be displayed. You can very easily format strings like that by adding bold, colors, ...
# in a more readable and easy-to-write way (but of course slower than direct-encoding)
# arg0: The 'rich' string to decode
# arg1: The name of the variable that will contain the result (a string ready to be echoed)
# Example:
#   str="~rHello~, _this_ ~yis~ a *formated* ~pc~~wo~~rn~~bt~~ge~~cn~~yt~; *_double ~bformated~_*"
#   string_rich str, result
#   echo "$result"
# The following 'encoding' are ready to be used:
# **...** > bold + white coloring
# *...* > bold
# _..._ > underline
# ++...++ > blink
# ~X...~ > color text with 'X' color, if lower case the font is colored otherwise the background is colored
# <cr> > will add a Cariage Return (new line)
# And you can use multiple of these on the same string.
function string_rich() {
  if [[ $# -eq 2 ]]; then
    local -n __RICH_STRING__=$2
    local copy="$1"
    local reg='(.*)(\*\*.+?\*\*)(.*)'
    while [[ $copy =~ $reg ]]; do
      copy="${BASH_REMATCH[1]}${FONT_BOLD}${COLOR_FG_WHITE}${BASH_REMATCH[2]//\*\*/}${FONT_RESET}${BASH_REMATCH[3]}"
    done
    reg='(.*)(\*.+?\*)(.*)'
    while [[ $copy =~ $reg ]]; do
      copy="${BASH_REMATCH[1]}${FONT_BOLD}${BASH_REMATCH[2]//\*/}${FONT_RESET}${BASH_REMATCH[3]}"
    done
    reg='(.*)(_.+?_)(.*)'
    while [[ $copy =~ $reg ]]; do
      copy="${BASH_REMATCH[1]}${FONT_UNDERLINE}${BASH_REMATCH[2]//_/}${FONT_RESET}${BASH_REMATCH[3]}"
    done
    reg='(.*)(\+\+.+?\+\+)(.*)'
    while [[ $copy =~ $reg ]]; do
      copy="${BASH_REMATCH[1]}${FONT_BLINK}${BASH_REMATCH[2]//\+/}${FONT_RESET}${BASH_REMATCH[3]}"
    done
    reg='(.*)(<cr>)(.*)'
    while [[ $copy =~ $reg ]]; do
      copy="${BASH_REMATCH[1]}
${BASH_REMATCH[3]}"
    done
    reg='(.*)(~[rgybmcwopaRGYBMCWOPA].+?~)(.*)'
    while [[ $copy =~ $reg ]]; do
      local color=""
      local substr=""
      string_charAt "${BASH_REMATCH[2]}" 1 color
      string_substr "${BASH_REMATCH[2]}" 2 $((${#BASH_REMATCH[2]} - 3)) substr
      case "$color" in
        r) color="${COLOR_FG_RED}";;
        R) color="${COLOR_BG_RED}";;
        g) color="${COLOR_FG_GREEN}";;
        G) color="${COLOR_BG_GREEN}";;
        b) color="${COLOR_FG_BLUE}";;
        B) color="${COLOR_BG_BLUE}";;
        y) color="${COLOR_FG_YELLOW}";;
        Y) color="${COLOR_BG_YELLOW}";;
        m) color="${COLOR_FG_MAGENTA}";;
        M) color="${COLOR_BG_MAGENTA}";;
        c) color="${COLOR_FG_CYAN}";;
        C) color="${COLOR_BG_CYAN}";;
        w) color="${COLOR_FG_WHITE}";;
        W) color="${COLOR_BG_WHITE}";;
        o) color="${COLOR_FG_ORANGE}";;
        O) color="${COLOR_BG_ORANGE}";;
        p) color="${COLOR_FG_PINK}";;
        P) color="${COLOR_BG_PINK}";;
        a) color="${COLOR_FG_GRAY}";;
        A) color="${COLOR_BG_GRAY}";;
      esac
      copy="${BASH_REMATCH[1]}$color$substr${COLOR_RESET}${BASH_REMATCH[3]}"
    done
    __RICH_STRING__="$copy"
  else
    bashlib_abort "$(caller)" "[string] [&result]"
  fi
}

# This function displays a 'rich' encoded string directly without returning it
# arg0: The rich string to display
# Example:
#   string_echoRich "Hello, I am *very* **VERY** important !"
function string_echoRich() {
  if [[ $# -eq 1 ]]; then
    local richStr=""
    string_rich "$1" richStr
    echo "$richStr"
  else
    bashlib_abort "$(caller)" "[string]"
  fi
}

# This function displays (as a 'rich' encoded string if required) a given string to a specific position before putting back the cursor at the initial position
# arg0: The (rich or not) string to display
# arg1: The X coordinate
# arg2: The Y coordiante
# arg3: A boolean (optional) saying if we want (true) or not (false) clear the entire line of the terminal after the string
function string_echoPosition() {
  if [[ $# -ge 3 ]]; then
    local richStr=""
    tput sc
    tput cup "$3" "$2"
    string_rich "$1" richStr
    echo -n "$richStr"
    if [[ $# -eq 4 ]] && [[ $4 == true ]]; then
      tput el
    fi
    tput rc
  else
    bashlib_abort "$(caller)" "[string] [X coordinate] [Y coordinate] {line clear wanted [T/F]}"
  fi
}

# This function checks if a given string contains a given substring
# arg0: The main string to check
# arg1: The substring we are looking for
# return: 0 if arg1 is present inside arg0, 1 otherwise
# Example:
#   if string_contains "Hello World !" "orl"; then
#     echo "Success !"
#   fi
function string_contains() {
  local __STRING_DOES_CONTAIN__=1
  if [[ $# -eq 2 ]]; then
    if [[ $1 == *"$2"* ]]; then
      __STRING_DOES_CONTAIN__=0
    fi
  else
    bashlib_abort "$(caller)" "[string] [substring to check]"
  fi
  return $__STRING_DOES_CONTAIN__
}

# This function fixes the size of a given string to a specific width value, truncating it if it's bigger or padding it with spaces if it's not
# arg0: The name of the variable that contains the string we want to fix the size
# arg1: The size to apply to the string
# Example:
#  str="012345"
#  string_fixSize str 2
#  echo "1 in 2-bit binary is: $str"
function string_fixSize() {
  if [[ $# -eq 2 ]]; then
    local -n __FIXED_SIZE_STRING__=$1
    local padding=""
    if [[ ${#__FIXED_SIZE_STRING__} -gt $2 ]]; then
      __FIXED_SIZE_STRING__=${__FIXED_SIZE_STRING__:0:$2}
    else
      padding=$(printf "%-$(($2 - ${#__FIXED_SIZE_STRING__}))s" "=")
      __FIXED_SIZE_STRING__="${__FIXED_SIZE_STRING__}${padding//=/ }"
    fi
  else
    bashlib_abort "$(caller)" "[&string] [targetSize]"
  fi
}

# This function checks if a given string can be interpreted as a number (with/without decimal values and with/without sign)
# arg0: The string to check
# return: 0 if the string is a number, 1 otherwise
# Note:
#   An integer or a floating value, with '-' or '+' sign as well, will be accepted as "number", if you don't want to check for floating value and only
#   bash-compatible value you can just simplify the regex to '^[0-9]+$'
function string_isNumber() {
  local __STRING_IS_NUMBER__=1
  if [[ $# -eq 1 ]]; then
    if [[ $1 =~ ^[+-]?[0-9]+([.][0-9]+)?$ ]]; then
      __STRING_IS_NUMBER__=0
    fi
  else
    bashlib_abort "$(caller)" "[string]"
  fi
  return $__STRING_IS_NUMBER__
}

# This function removes from a string all non-printable (alphanumeric) characters
# arg0: The string to clean
function string_removeNonPrintable() {
  if [[ $# -eq 1 ]]; then
    local -n __STRING_TO_SANITIZE__=$1
    __STRING_TO_SANITIZE__=$(echo "$__STRING_TO_SANITIZE__" | tr -cd '\11\12\15\40-\176')
  else
    bashlib_abort "$(caller)" "[&string]"
  fi
}
