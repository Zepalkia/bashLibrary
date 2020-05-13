source variables.sh
source math.sh

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

#arg0: x
#arg1: y
#arg2: width
#arg3: msg
function ui_echoWindow() {
  tput sc
  local xOrigin=$1
  local yOrigin=$2
  local message="$4"
  local width=0
  math_min $(($(tput cols) - xOrigin - 3)) "$3" width

  tput rc
}

function ui_menu() {
  if [[ $# -eq 2 ]]; then
    true
  else
    false
  fi
}

