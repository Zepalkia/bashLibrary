# This will force the use of xterm-256 color if present in the system, e.g. when using linux terminal you'll be able to use 256-color instead of 8
if [[ "$TERM" != "xterm-256color" ]]; then
  if [[ -f /lib/terminfo/x/xterm-256color ]] || [[ -f /usr/lib/terminfo/x/xterm-256color ]]; then
    TERM="xterm-256color"
  fi
fi
# This part will setup the available color-variable, either 8 if no more are available or the base 8 (with nicer colors) + few more. You can add or change those
# value based on your preferences/setup, to display how the 256 colors are looking on your computer you can simply run the following command:
# for ((i=0; i < 256; ++i)); do echo -e "$(tput setab $i)$(printf "%03d" $i)$(tput sgr0)"; done
if [[ $(tput colors) == 8 ]]; then
  COLOR_RESET="$(tput setaf 9)$(tput setab 9)"
  COLOR_FG_RED="$(tput setaf 1)"
  COLOR_BG_RED="$(tput setab 1)"
  COLOR_FG_BLINKING_RED="$(tput blink)$COLOR_FG_RED"
  COLOR_FG_GREEN="$(tput setaf 2)"
  COLOR_BG_GREEN="$(tput setab 2)"
  COLOR_FG_YELLOW="$(tput setaf 3)"
  COLOR_BG_YELLOW="$(tput setab 3)"
  COLOR_FG_BLUE="$(tput setaf 4)"
  COLOR_BG_BLUE="$(tput setab 4)"
  COLOR_FG_MAGENTA="$(tput setaf 5)"
  COLOR_BG_MAGENTA="$(tput setab 6)"
  COLOR_FG_CYAN="$(tput setaf 6)"
  COLOR_BG_CYAN="$(tput setab 6)"
  COLOR_FG_WHITE="$(tput setaf 7)"
  COLOR_BG_WHITE="$(tput setab 7)"
elif [[ $(tput colors) == 256 ]]; then
  COLOR_RESET="$(tput sgr0)"
  COLOR_FG_RED="$(tput setaf 9)"
  COLOR_BG_RED="$(tput setab 9)"
  COLOR_FG_BLINKING_RED="$(tput blink)$COLOR_FG_RED"
  COLOR_FG_GREEN="$(tput setaf 10)"
  COLOR_BG_GREEN="$(tput setab 10)"
  COLOR_FG_YELLOW="$(tput setaf 11)"
  COLOR_BG_YELLOW="$(tput setab 11)"
  COLOR_FG_BLUE="$(tput setaf 12)"
  COLOR_BG_BLUE="$(tput setab 12)"
  COLOR_FG_MAGENTA="$(tput setaf 13)"
  COLOR_BG_MAGENTA="$(tput setab 13)"
  COLOR_FG_CYAN="$(tput setaf 14)"
  COLOR_BG_CYAN="$(tput setab 14)"
  COLOR_FG_WHITE="$(tput setaf 15)"
  COLOR_BG_WHITE="$(tput setab 15)"
  COLOR_FG_ORANGE="$(tput setaf 130)"
  COLOR_BG_ORANGE="$(tput setab 130)"
  COLOR_FG_PINK="$(tput setaf 177)"
  COLOR_BG_PINK="$(tput setab 177)"
  COLOR_FG_GRAY="$(tput setaf 240)"
  COLOR_BG_GRAY="$(tput setab 240)"
fi
FONT_BOLD=$(tput bold)
FONT_UNDERLINE=$(tput smul)
FONT_COLOR_REVERSE=$(tput rev)
FONT_BLINK=$(tput blink)
FONT_INVISIBLE=$(tput invis)
FONT_RESET=$(tput sgr0)
# This function stops the script execution and display an error to the user, used internally by the library to manage the wrong usage of functions
# arg0: The $(caller) result as a string
# arg1: The message to display to the user
function bashlib_abort() {
  local line=""
  local component=""
  line=$(echo "$1" | awk '{print $1}')
  component=$(echo "$1" | awk '{print $2}')
  if [[ "$component" != "NULL" ]]; then
    echo -e "[${COLOR_FG_RED}Error${COLOR_RESET}] Bad usage of ${FUNCNAME[1]}: $2 (called from $component at line $line)"
    exit 1
  else
    echo -e "[${COLOR_FG_RED}Error${COLOR_RESET}] Bad usage of ${FUNCNAME[1]}: $2 (called by an interactive terminal)"
  fi
}
# This function allows to declare some error code that will trigger a unique user-defined 'quit' function. Such function named '__EXIT__' is expected to be
# declared BEFORE calling this function and will receive as an argument the error code given when declaring it
# The purpose is only to be able to make bash scripts more readable and to handle in a single place the exit  alues and behaviour by simply declaring error name
# that will then become "dynamic" functions
# arg0: The name of the error
# arg1: The error code
# arg2: (optional) The error message that will be sent to the '__EXIT__' function
# Example:
#   function __EXIT__() { echo "I leave now with error code '$1' (called from ${FUNCNAME[2]})"; exit $1; }
#   bashlib_declareErrno "EXIT_FAILURE" "1"
#   bashlib_declareErrno "EXIT_SUCCESS" "0"
#   bashlib_declareErrno "EXIT_WRONG_ARGUMENT" "2" "wrong argument given"
#   EXIT_SUCCESS
# Note:
# In your __EXIT__ function, in addition to the errno ($1) and optional error message ($2) you can easily retrieve the name of the function that triggered it
# which is stored inside ${FUNCNAME[2]}
function bashlib_declareErrno() {
  if [[ $# -ge 2 ]]; then
    if [[ "$(type -t __EXIT__)" == "function" ]]; then
      local msg=""
      if [[ $# -eq 3 ]]; then
        msg="$3"
      fi
      source /dev/stdin << EOF
function $1() {
  __EXIT__ $2 "$msg"
}
EOF
    else
      bashlib_abort "$(caller)" "a generic function __EXIT__ needs to be defined"
    fi
  else
    bashlib_abort "$(caller)" "[error name] [error code] {error message}"
  fi
}
