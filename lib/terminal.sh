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
    read -sdR cursorPosition
    cursorPosition=${cursorPosition#*[}
    value=$(echo "$cursorPosition" | awk -F ';' '{print $1}')
    $(test $value -eq $value &>/dev/null) || value=0
    __CURSOR_LINE__=$((value - 2))
  else
    false
  fi
}

function terminal_mouseClick() {
  if [[ $# -eq 4 ]]; then
    local -n __BUTTON_CLICKED__=$1
    local -n __CLICK_X_POSITION__=$2
    local -n __CLICK_Y_POSITION__=$3
    local click=""
    local count=0
    stty -echo
    tput sc
    tput cup "$(($(tput lines)-2))" 0
    echo -e "\e[?1000;1006;1015h"
    tput rc
    read -rn 18 click
    tput sc
    tput cup "$(($(tput lines)-2))" 0
    echo -e "\e[?1000;1006;1015l"
    tput rc
    stty echo
  else
    false
  fi
}
