source variables.sh
source math.sh
source terminal.sh
source string.sh

# This function shows formated message to display status to the user
# arg0: The level of the message
# arg1: THe message to display
# The following levels are valid:
#   'emg' or 'emergency' -> red blinking
#   'err' or 'error' -> red
#   'war' or 'warning' -> yellow
#   'inf' or 'info' -> green
function ui_showMessage() {
  if [[ $# -eq 2 ]]; then
    case "$1" in
      emg|emergency) echo -e "[${COLOR_FG_BLINKING_RED}Emergency${COLOR_RESET}] $2";;
      err|error) echo -e "[${COLOR_FG_RED}Error${COLOR_RESET}] $2";;
      war|warning) echo -e "[${COLOR_FG_YELLOW}Warning${COLOR_RESET}] $2";;
      inf|info) echo -e "[${COLOR_FG_GREEN}Info${COLOR_RESET}] $2";;
    esac
  else
    false
  fi
}

# This function displays a given message in a nice-looking GUI-like window drawn in ascii art with a dynamic (optional) user interation
#arg0: The X position of the window top-left corner
#arg1: The Y position of the window top-left corner
#arg2: The width of the window
#arg3: The message (string) to display inside the window
#arg4: A string defining the kind of window expected, valid values are:
#  - '' (empty): Will just display the window with the message without any other action
#  - 'OK': Will wait for the user to press a key and then clear the window
#  - 'YN': Will display a dynamic 'yes/no' choice (using arrow keys), clear the window and put the answer into the return value
#arg5: The name of the variable that will contain the return value (if any, optional)
# This function is not really useful but shows an easy example about how to do this kind of things. Be aware than the width has to be big enough and that any
# text already displayed under the window will be forever deleted !
# If you want to show a big warning message it could be a nice idea to switch to the secondary screen if available, then print the window waiting for the user
# and then going back (this can be automatically achieved by 'ui_confirmWindow' or 'ui_okWindow')
function ui_echoWindow() {
  if [[ $# -ge 5 ]]; then
    tput sc
    local xOrigin=$1
    local yOrigin=$2
    local message="$4"
    local localClear=$5
    [[ $# -eq 6 ]] && local -n __USER_CHOICE__=$6
    local width=0
    local nChar=0
    local line=1
    local box=""
    local xRight=0
    math_min $(($(tput cols) - xOrigin - 3)) "$3" width
    xRight=$((xOrigin + width - 1 - width % 2))
    box=$(printf "%-$((width / 2 - 1))s" " ")
    tput cup $yOrigin $xOrigin
    echo "+${box// /=~}+"
    tput cup $((yOrigin + line)) $xOrigin
    for word in $message; do
      if [[ $nChar -eq 0 ]]; then
        str="| $word ";
      else
        str="$word "
      fi
      if [[ $((${#str} + nChar)) -lt $((width - 1)) ]]; then
        echo -n "$str"
        nChar=$((${#str} + nChar))
      else
        string_substr "$str" 0 $((width - 2 - ${#str} - nChar)) result
        string_substr "$str" $((width -2 - ${#str} - nChar)) ${#str} leftovers
        echo -n "$result"
        tput cup $((yOrigin + line)) $xRight
        echo -n "|"
        line=$((line + 1))
        tput cup $((yOrigin + line)) $xOrigin
        echo -n "| $leftovers"
        nChar=$((3 + ${#leftovers}))
      fi
    done
    tput cup $((yOrigin + line)) $xRight
    echo -n "|"
    tput cup $((yOrigin + line + 1)) $xOrigin
    case "$localClear" in
      OK|YN)
        echo -n "| "
        if [[ "$localClear" == "OK" ]]; then
          tput cup $((yOrigin + line + 1)) $((xOrigin + width / 2))
          echo -en "${COLOR_BG_GRAY}OK${COLOR_RESET}"
        else
          tput cup $((yOrigin + line + 1)) $((xOrigin + width / 2 - 5))
          echo -en "${COLOR_BG_GRAY}YES${COLOR_RESET}   NO"
        fi
        tput cup $((yOrigin + line + 1)) $xRight
        echo -n "|"
        tput cup $((yOrigin + line + 2)) $xOrigin
        echo "+${box// /=~}+"
        if [[ "$localClear" == "OK" ]]; then
          read -n 1
          for((l=0; l < $((line + 3)); ++l)); do
            tput cup $((yOrigin + l)) $xOrigin
            echo " ${box// /  } "
          done
        else
          key=""
          __USER_CHOICE__=true
          while [[ "$key" == "" ]] || [[ "$key" != "NONE" ]]; do
            terminal_readArrowKey key
            if [[ "$key" == "RIGHT" ]]; then
              tput cup $((yOrigin + line + 1)) $((xOrigin + width / 2 - 5))
              echo -en "YES   ${COLOR_BG_GRAY}NO${COLOR_RESET}"
              __USER_CHOICE__=false
            elif [[ "$key" == "LEFT" ]]; then
              tput cup $((yOrigin + line + 1)) $((xOrigin + width / 2 - 5))
              echo -en "${COLOR_BG_GRAY}YES${COLOR_RESET}   NO"
              __USER_CHOICE__=true
            fi
          done
          for((l=0; l < $((line + 3)); ++l)); do
            tput cup $((yOrigin + l)) $xOrigin
            echo " ${box// /  } "
          done
        fi
        ;;
      *)
        tput cup $((yOrigin + line + 1)) $xOrigin
        echo "+${box// /=~}+"
        ;;
    esac
    tput rc
  else
    false
  fi
}

function ui_confirmWindow() {
  if [[ $# -eq 6 ]]; then
    local -n __CONFIRMED_VALUE__=$6
    if [[ $5 == true ]]; then
      tput smcup
    fi
    ui_echoWindow "$1" "$2" "$3" "$4" "YN" __CONFIRMED_VALUE__
    if [[ $5 == true ]]; then
      tput rmcup
    fi
    true
  else
    false
  fi
}

# This function displays a window with a given message that will stay displayed until the user press 'enter'
# arg0: The X position of the top-left corner
# arg1: The Y position of the top-left corner
# arg2: The width of the window
# arg3: The message to display inside the window
# arg4: A boolean telling if we want (true) or not (false) to display the window into the secondary screen (will auto-backup the current content of the screen)
function ui_okWindow() {
  if [[ $# -eq 5 ]]; then
    if [[ $5 == true ]]; then
      tput smcup
    fi
      ui_echoWindow "$1" "$2" "$3" "$4" "OK"
    if [[ $5 == true ]]; then
      tput rmcup
    fi
  else
    false
  fi
}

# This function prints an horizontal rule from the current cursor position to the last column of the terminal
# Example:
#   tput cup 10 0
#   ui_horizontalRule
function ui_horizontalRule() {
  local rule=$(printf "%-$(tput cols)s" "=")
  echo -e "${COLOR_FG_WHITE}${FONT_BOLD}${rule// /=}${NORMAL}"
}

# arg0: The array of list entries (strings with prepended '#' for each level of the entry)
# arg1: String defining the kind of list we want (optional, bullet by default)
# Example:
#
# The element of arg0 should have a '#' at the beginning to define the depth of the following string in the lists, e.g. ## will be depth = 2
# The following type of list can be given as arg1:
#  'N' or 'numbered' -> creates a numbered list using roman/arabic numerals
#  'L' or 'letters' -> creates a alphabetic list using letters
#  'T' or 'steps' -> creates a list of steps & substeps using extended ascii chars '├' and '└'
#  'S' or 'symbols' -> creates a bullet list using symbols (default)
function ui_list() {
  if [[ $# -ge 1 ]]; then
    local listArray="$1[@]"
    local listKind="symbols"
    local depth=0
    [[ $# -eq 2 ]] && listKind="$2"
    for entry in "${listArray[@]}"; do
      true
    done
  else
    false
  fi
}


function ui_menu() {
  if [[ $# -eq 2 ]]; then
    true
  else
    false
  fi
}

