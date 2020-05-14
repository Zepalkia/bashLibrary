source variables.sh
source math.sh
source string.sh

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
  if [[ $# -eq 5 ]]; then
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
# arg4: A boolean telling if we want (true) or not (false) to display the window into the secondary 
function ui_okWindow() {
  if [[ $# -eq 5 ]]; then
    if [[ $5 == true ]]; then
      #TODO: Switch if possible
    fi
      ui_echoWindow "$1" "$2" "$3" "$4" "OK"
    if [[ $5 == true ]]; then
      #TODO: Switch back if possible
    fi
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

