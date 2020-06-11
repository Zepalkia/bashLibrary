source variables.sh

# This function shows a prompt to the user that contains a default value that will be selected if the user doesn't enter anything
# arg0: The default value returned by the function and shown to the user if no other value is entered
# arg1: The name of the variable that will contain the prompt value (or the default one)
# Example:
#   prompt_readWithDefault Default result
#   Will display a prompt looking like that:
#   > |Default
#   With '|' being the cursor, if the user press 'enter' it will return 'Default', otherwise 'Default' will become invisible and what the user is
#   typing will be shown instead. If the user then deletes everything and press enter 'Default' will be returned making it a true default value
function prompt_readWithDefault() {
  if [[ $# -eq 2 ]]; then
    local input1=""
    local input2=""
    local nChars=""
    local -n __READ_VALUE__=$2
    nChars=$(printf "%-$((${#1} + 3))s" " ")
    echo -en "> ${COLOR_FG_GRAY}$1${COLOR_RESET}"
    tput civis
    read -rn 1 input1
    if [[ ${#input1} -eq 0 ]]; then
      __READ_VALUE__=$1
    else
      tput cvvis
      echo -en "\b \r${nChars// / }\r"
      read -rp "> " -ei "$input1" input2
      if [[ ${#input2} -eq 0 ]]; then
        __READ_VALUE__=$1
      else
        __READ_VALUE__=$input2
      fi
    fi
    tput cvvis
  else
    bashlib_abort "$(caller)" "[default value] [&result]"
  fi
}

# This function shows a yes/no prompt to the user with a given message and an optional default answer
# arg0: The message asking for confirmation, nothing will be added to it
# arg1: (optional) The default answer if the user just press enter (should be y/Y/yes/Yes or n/N/no/No to be valid)
# arg2: The name of the variable that will contain the result (boolean)
# Example:
#   prompt_confirmation "Do you agree with me ? [y/n] " result
#   [[ $result == true ]] && echo "Thank you !" || echo "Too bad :("
# See also 'ui_confirmWindow'
function prompt_confirmation() {
  local valid=false
  local input=""
  if [[ $# -eq 2 ]]; then
    local -n __CONFIRMATION_VALUE__=$2
    valid=true
    read -rp "$1" input
  elif [[ $# -eq 3 ]]; then
    local -n __CONFIRMATION_VALUE__=$3
    valid=true
    echo -e "$1"
    prompt_readWithDefault "$2" input
  else
    bashlib_abort "$(caller)" "[message] {default answer} [&result]"
  fi
  if [[ $valid == true ]]; then
    while true; do
      case "$input" in
        y|Y|yes|Yes)
          __CONFIRMATION_VALUE__=true
          break;;
        n|N|no|No)
          __CONFIRMATION_VALUE__=false
          break;;
        *) read -rp "Please answer 'yes' or 'no': " choice;;
      esac
    done
  fi
}

# tab completion ?
