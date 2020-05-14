#@PRIORITY: 8
source string.sh

# This function returns the current line position of the cursor (first line being 0)
# args0: The name of the variable that will contain the final value
# Example:
#   terminal_getCursorLine line
#   echo "Your cursor is at line $((line+1))"
function terminal_getCursorLine() {
  if [[ $# -eq 1 ]]; then
    local -n __CURSOR_LINE__=$1
    local value=0
    local cursorPosition=""
    echo -en "\033[6n"
    # shellcheck disable=SC2162
    # Very-specific read, we need to specifically avoid putting -r here to make it work
    read -sdR cursorPosition
    cursorPosition=${cursorPosition#*[}
    value=$(echo "$cursorPosition" | awk -F ';' '{print $1}')
    test "$value" -eq "$value" || value=0
    __CURSOR_LINE__=$((value - 2))
  else
    false
  fi
}

# This function waits for the user to click on the terminal and return the informations about this click event
# arg0: The name of the variable that will contain which button is clicked (0 = left, 1 = middle, 2 = right)
# arg1: The X position in the terminal that has been clicked (column)
# arg2: The Y position in the terminal that has been clicked (row)
# Example:
#   terminal_mouseClick button x y
#   tput sc; tput cup $y $x; echo "X"; tput rc
# This is of course something that will not work at all in text-only terminal and non-xterm compatible ones as it needs a very-specific trigger to read the
# mouse events.
function terminal_mouseClick() {
  if [[ $# -eq 3 ]]; then
    local -n __BUTTON_CLICKED__=$1
    local -n __CLICK_X_POSITION__=$2
    local -n __CLICK_Y_POSITION__=$3
    local click=""
    local result=0
    local tokens=()
    stty -echo
    echo -en "\e[?1000;1006;1015h"
    read -rsn 11 click
    echo -en "\e[?1000;1006;1015l"
    string_tokenize "$click" ";" tokens
    if [[ "${#tokens[@]}" -gt 2 ]]; then
      string_substr "${tokens[2]}" 0 2 result
      result=${result/M/}
    else
      result=${tokens[2]/M/}
    fi
    __BUTTON_CLICKED__=${tokens[0]}
    __CLICK_X_POSITION__=$((${tokens[1]} - 1))
    __CLICK_Y_POSITION__=$((result - 1))
    stty echo
  else
    false
  fi
}

# This function awaits for the user to use one of the 4 directonal arrow-keys
# arg0: The name of the variable that will contain which key have been pressed (readable string)
# Example:
#   terminal_readArrowKey arrow
#   echo "The user pressed the direction: $arrow"
#
# There're plenty of ways to implement this, each with its pros and cons. I choose to integrate this one because it's to my opinion the more readable and easiest
# to understand and does the job done just fine in most of the situations.
# 'space' or 'enter' key are exiting this function with 'NONE' as a return value.
function terminal_readArrowKey() {
  if [[ $# -eq 1 ]]; then
    local -n __READ_ARROW__=$1
    local escape=$(printf "\u1b")
    local input=""
    while true; do
      read -rsn 1 input
      if [[ "$input" == "$escape" ]]; then
        read -rsn 2 input
        case "$input" in
          "[A")
            __READ_ARROW__="UP"
            break;;
          "[B")
            __READ_ARROW__="DOWN"
            break;;
          "[D")
            __READ_ARROW__="LEFT"
            break;;
          "[C")
            __READ_ARROW__="RIGHT"
            break;;
          *);;
        esac
      elif [[ "$input" == "" ]]; then
        __READ_ARROW__="NONE"
        break
      fi
    done
  else
    false
  fi
}
