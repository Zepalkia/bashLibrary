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
    read -sdR cursorPosition < /dev/tty
    cursorPosition=${cursorPosition#*[}
    value=$(echo "$cursorPosition" | awk -F ';' '{print $1}')
    test "$value" -eq "$value" || value=0
    __CURSOR_LINE__=$((value - 2))
  else
    bashlib_abort "$(caller)" "[&result]"
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
    read -rsn 18 click
    echo -en "\e[?1000;1006;1015l"
    string_tokenize "$click" ";" tokens
    if [[ "${#tokens[@]}" -gt 2 ]]; then
      string_substr "${tokens[2]}" 0 2 result
      result=${result//[mM]/}
    else
      result=${tokens[2]//[mM]/}
    fi
    __BUTTON_CLICKED__=${tokens[0]}
    __CLICK_X_POSITION__=$((tokens[1] - 1))
    __CLICK_Y_POSITION__=$((result - 1))
    read -rt 0.1
    stty echo
  else
    bashlib_abort "$(caller)" "[&result0 (button)] [&result1 (X)] [&result2 (Y)]"
  fi
}

# This function awaits for the user to use one of the 4 directonal arrow-keys
# arg0: (optional) A boolean telling if we want to read any key (true) or only the arrow keys (false, default)
# arg1: The name of the variable that will contain which key have been pressed (readable string)
# Example:
#   terminal_readArrowKey arrow
#   echo "The user pressed the direction: $arrow"
#
# There're plenty of ways to implement this, each with its pros and cons. I choose to integrate this one because it's to my opinion the more readable and easiest
# to understand and does the job done just fine in most of the situations.
# 'space' or 'enter' key are exiting this function with 'NONE' as a return value.
function terminal_readArrowKey() {
  if [[ $# -ge 1 ]]; then
    if [[ $# -eq 1 ]]; then
      local -n __READ_ARROW__=$1
    else
      local readAll=$1
      local -n __READ_ARROW__=$2
    fi
    local escape=""
    local input=""
    escape=$(printf "\u1b")
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
      elif [[ $readAll == true ]]; then
        __READ_ARROW__=$input
        break
      fi
    done
  else
    bashlib_abort "$(caller)" "[&result]"
  fi
}

# This function is able to handle multiple kind of event at once, it awaits for any user interaction and returns which interaction and the result
# arg0: The name of the variable that will contain the value of the event (depends on the event, see notes)
# arg1: The name of the variable that will contain the type of the event (see notes)
# Example:
#   terminal_readEvent value type
#   echo "An event of type [$type] has been catched, result: [$value]"
# Note:
# This function will handle the following kind of events:
# - mouse:
#     Any mouse click on the terminal, the 'value' will contain the button click and the <x,y> position of the click in the format 'button;x;y'
# - arrow:
#     An arrow key has been used, the 'value' will contain the direction (UP, DOWN, LEFT or RIGHT)
# - validation:
#     The 'enter' or 'space' key is pressed, the 'value' will not contain anything
# - special:
#     Any of these special key: "tab", "back"
# - key:
#     Any other keyboard key has been pressed, the 'value' will contain the char that has been entered
function terminal_readEvent() {
  if [[ $# -eq 2 ]]; then
    local escape=""
    local input=""
    local -n __READ_EVENT__=$1
    local -n __TYPE_EVENT__=$2
    local oldIFS=$IFS
    IFS=""
    escape=$(printf "\u1b")
    stty -echo
    echo -en "\e[?1000;1006;1015h"
    read -rsn 1 input
    echo -en "\e[?1000;1006;1015l"
    stty echo
    case "$input" in
      $escape)
      read -rsn 2 input
      __TYPE_EVENT__="arrow"
      case "$input" in
        "[A") __READ_EVENT__="UP";;
        "[B") __READ_EVENT__="DOWN";;
        "[D") __READ_EVENT__="LEFT";;
        "[C") __READ_EVENT__="RIGHT";;
        "[<")
          __TYPE_EVENT__="mouse"
          read -rst 0.1 input
          string_tokenize "$input" ";" input
          __READ_EVENT__="${input[0]};${input[1]};${input[2]//M/}"
          ;;
      esac;;
      $'\x09')
        __READ_EVENT__="tab"
        __TYPE_EVENT__="special"
        ;;
      $'\x7f')
        __READ_EVENT__="back"
        __TYPE_EVENT__="special"
        ;;
      "")
        __TYPE_EVENT__="validation";;
      *)
        __READ_EVENT__="$input"
        __TYPE_EVENT__="key";;
    esac
    IFS=$oldIFS
  else
    bashlib_abort "$(caller)" "[&result0 (value)] [&result1 (type)]"
  fi
}
