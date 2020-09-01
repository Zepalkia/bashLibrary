source variables.sh
source string.sh
source terminal.sh

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
    read -rn 1 input1 < /dev/tty
    if [[ ${#input1} -eq 0 ]]; then
      __READ_VALUE__=$1
    else
      tput cvvis
      echo -en "\b \r${nChars// / }\r"
      read -rp "> " -ei "$input1" input2 < /dev/tty
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
    read -rp "$1" input < /dev/tty
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
        *) read -rp "Please answer 'yes' or 'no': " input < /dev/tty;;
      esac
    done
  fi
}

# This function creates a prompt with auto-completion capabilities, it will display up to 10 completion choices that can be navigated with the arrow keys and
# completed with the TAB key (ENTER will validate the input)
# arg0: The name of the variable (array) containing the list of available completions
# arg1: The name of the variable that will contain the input from the user
function prompt_readWithCompletion() {
  if [[ $# -eq 2 ]]; then
    local -n argArray=$1
    local -n __READ_WITH_COMPLETION__=$2
    local flatArray="${argArray[*]}"
    local nOptions=${#argArray[@]}
    local value=""
    local eventType=""
    local completionList=""
    local temporaryValue=""
    local line=0
    local count=0
    # The max width of a line, any completion value bigger than this will be truncated
    local maxWidth=20
    local countLine=0
    local selectedLine=0
    local completeArray=()
    local looping=true
    __READ_WITH_COMPLETION__=""
    terminal_getCursorLine line
    line=$((++line))
    echo -n "> "
    while [[ $looping == true ]]; do
      terminal_readEvent value eventType
      case "$eventType" in
        key)
          __READ_WITH_COMPLETION__="$__READ_WITH_COMPLETION__$value"
          ;;
        special)
          if [[ "$value" == "back" ]]; then
            __READ_WITH_COMPLETION__=${__READ_WITH_COMPLETION__%?}
          elif [[ "$value" == "tab" ]]; then
            __READ_WITH_COMPLETION__="${completeArray[$selectedLine]}"
          fi
          ;;
        arrow)
          if [[ "$value" == "UP" ]] && [[ $selectedLine -gt 0 ]]; then
            selectedLine=$((--selectedLine))
          elif [[ "$value" == "DOWN" ]] && [[ $selectedLine -lt $((${#completeArray[@]} - 1)) ]]; then
            selectedLine=$((++selectedLine))
          fi
          ;;
        validation) looping=false;;
      esac
      if [[ $looping == true ]]; then
        completionList=""
        #shellcheck disable=SC2207 disable=SC1087 disable=SC2046 disable=SC2005
        #TODO: Cross-check this ugly double-echo resolving
        completeArray=($(echo $(echo "$flatArray" | grep -oE "[[:graph:]]*$__READ_WITH_COMPLETION__[[:graph:]]*")))
        if [[ $selectedLine -gt ${#completeArray[@]} ]]; then
          selectedLine=$((${#completeArray[@]} - 1))
        fi
        temporaryValue=" ${#completeArray[@]}/$nOptions"
        string_fixSize temporaryValue $maxWidth
        completionList="$completionList\n$temporaryValue"
        countLine=$((line + 2))
        count=0
        while [[ $countLine -lt $(tput lines) ]] && [[ $count -lt 10 ]] && [[ $count -lt ${#completeArray[@]} ]]; do
          if [[ $count -eq $selectedLine ]]; then
            temporaryValue="| ${completeArray[$count]}"
          else
            temporaryValue="${completeArray[$count]}"
          fi
          string_fixSize temporaryValue $maxWidth
          completionList="$completionList\n$temporaryValue"
          count=$((++count))
          countLine=$((++countLine))
        done
        while [[ $countLine -lt $(tput lines) ]] && [[ $count -lt 10 ]]; do
          temporaryValue=""
          string_fixSize temporaryValue $maxWidth
          completionList="$completionList\n$temporaryValue"
          count=$((++count))
          countLine=$((++countLine))
        done
        echo -e "$completionList"
        tput cup "$line" 0
        echo -n "> $__READ_WITH_COMPLETION__"
        tput el
      fi
    done
    echo ""
  else
    bashlib_abort "$(caller)" "[array of options] [&result]"
  fi
}
