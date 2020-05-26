#@PRIORITY: 7
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
    false
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
# ~X...~ > color text with 'X' color
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
    reg='(.*)(~[rgybmcwopa].+?~)(.*)'
    while [[ $copy =~ $reg ]]; do
      local color=""
      local substr=""
      string_charAt "${BASH_REMATCH[2]}" 1 color
      string_substr "${BASH_REMATCH[2]}" 2 $((${#BASH_REMATCH[2]} - 3)) substr
      case "$color" in
        r) color="${COLOR_FG_RED}";;
        g) color="${COLOR_FG_GREEN}";;
        b) color="${COLOR_FG_BLUE}";;
        y) color="${COLOR_FG_YELLOW}";;
        m) color="${COLOR_FG_MAGENTA}";;
        c) color="${COLOR_FG_CYAN}";;
        w) color="${COLOR_FG_WHITE}";;
        o) color="${COLOR_FG_ORANGE}";;
        p) color="${COLOR_FG_PINK}";;
        a) color="${COLOR_FG_GRAY}";;
      esac
      copy="${BASH_REMATCH[1]}$color$substr${COLOR_RESET}${BASH_REMATCH[3]}"
    done
    __RICH_STRING__="$copy"
  else
    false
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
    false
  fi
}
