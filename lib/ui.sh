#@DEPENDENCIES: inotify-tools
source variables.sh
source math.sh
source terminal.sh
source string.sh
source threads.sh
source lockable.sh

# This function shows formated message to display status to the user
# arg0: The level of the message
# arg1: The message to display
# The following levels are valid:
#   'emg' or 'emergency' -> red blinking
#   'err' or 'error' -> red
#   'war' or 'warning' -> yellow
#   'inf' or 'info' -> green
# Note:
#   To display the same message in a graphical window, please check the 'gui_showMessage' function
function ui_showMessage() {
  if [[ $# -eq 2 ]]; then
    case "$1" in
      emg|emergency) string_echoRich "[*~r++Emergency++~*] $2";;
      err|error) string_echoRich "[*~rError~*] $2";;
      war|warning) string_echoRich "[*~yWarning~*] $2";;
      inf|info) string_echoRich "[*~gInfo~*] $2";;
    esac
  else
    bashlib_abort "$(caller)" "[level] [message]"
  fi
}

# This function returns the <x,y> top-left coordinate to use to start printing something at the center of the screen (a window, a text, ...)
# arg0: The width of the 'something' that will be printed
# arg1: The height of the 'something' that will be printed
# arg2: The variable that will contain the top-left X position
# arg3: The variable that will contain the top-left Y position
# Example:
#   ui_centerTopLeft 30 5 x y
#   ui_confirmWindow $x $y 30 "Do you agree ?" true result
function ui_centerTopLeft() {
  if [[ $# -eq 4 ]]; then
    local -n __CENTER_X_POSITION__=$3
    local -n __CENTER_Y_POSITION__=$4
    __CENTER_X_POSITION__=$(($(tput cols) / 2 - $1 / 2))
    __CENTER_Y_POSITION__=$(($(tput lines) / 2 - $2 / 2))
  else
    bashlib_abort "$(caller)" "[width] [height] [&result0 (X)] [&result1 (Y)]"
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
    local lines=()
    local localClear=$5
    [[ $# -eq 6 ]] && local -n __USER_CHOICE__=$6
    local width=0
    local nChar=0
    local line=1
    local box=""
    local xRight=0
    local result=""
    local leftovers=""
    math_min $(($(tput cols) - xOrigin - 3)) "$3" width
    mapfile -t lines < <(echo "$4" | fold -w "$((width - 3))" -s)
    xRight=$((xOrigin + width - 1 - width % 2))
    box=$(printf "%-$((width / 2 - 1))s" " ")
    tput cup "$yOrigin" "$xOrigin"
    echo "+${box// /=~}+"
    tput cup $((yOrigin + line)) "$xOrigin"
    for message in "${lines[@]}"; do
      echo -n "| $message"
      tput cup $((yOrigin + line)) "$xRight"
      echo -n "|"
      line=$((line + 1))
      tput cup $((yOrigin + line)) "$xOrigin"
    done
    tput cup $((yOrigin + line)) "$xOrigin"
    echo -n "|"
    tput cup $((yOrigin + line)) "$xRight"
    echo -n "|"
    tput cup $((yOrigin + line + 1)) "$xOrigin"
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
        tput cup $((yOrigin + line + 2)) "$xOrigin"
        echo "+${box// /=~}+"
        if [[ "$localClear" == "OK" ]]; then
          read -rn 1
          for((l=0; l < $((line + 3)); ++l)); do
            tput cup $((yOrigin + l)) "$xOrigin"
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
            tput cup $((yOrigin + l)) "$xOrigin"
            echo " ${box// /  } "
          done
        fi
        ;;
      *)
        tput cup $((yOrigin + line + 1)) "$xOrigin"
        echo "+${box// /=~}+"
        ;;
    esac
    tput rc
  else
    bashlib_abort "$(caller)" "[top-left X] [top-left Y] [width] [message] [kind of window] {&result}"
  fi
}

# This function displays a window with a 'yes/no' interface to the user.
# arg0: The X top-left corner of the window
# arg1: The Y top-left corner of the window
# arg2: The width of the window
# arg3: The message to dislay inside the window
# arg4: A boolean telling if we want to use the secondary screen to display only the window without breaking the current terminal content or not
# arg5: The name of the variable that will contain the answer of the user
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
  else
    bashlib_abort "$(caller)" "[top-left X] [top-left Y] [width] [message] [backup screen (T/F)] [&result]"
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
    bashlib_abort "$(caller)" "[top-left X] [top-left Y] [widt] [message] [backup screen (T/F)]"
    false
  fi
}

# This function prints an horizontal rule from the current cursor position to the last column of the terminal
# Example:
#   tput cup 10 0
#   ui_horizontalRule
function ui_horizontalRule() {
  local rule=""
  rule=$(printf "%-$(tput cols)s" "=")
  echo -e "${COLOR_FG_WHITE}${FONT_BOLD}${rule// /=}${COLOR_RESET}"
}

# This function displays and handles a multi-choice menu that map the list of available options with single-characters value (enhanced 'select' operator)
# arg0: The name of the array containing available options
# arg1: A boolean telling if we want to retrieve the entered string (true) or the array of option chosen
# arg2: The name of the variable that will contain the selection (array)
# Example:
#   options=(opt1 opt2 opt3)
#   ui_codebasedMenu options false result
#   echo "The user selected the following options: ${result[@]}"
#
# The menu displayed with the above example will look like:
# 0 -- opt1
# 1 -- opt2
# 2 -- opt3
# > |
# The user will be able to give a string (e.g. '20') to select multiple options (e.g. opt3 and opt1)which then will be converted back into the name of the option
# and returned to the caller. The menu will automatically be drawn on multiple columns if there's not enough lines to display all the options  in 1 and the full
# alphanumeric chars are available (0-9a-zA-Z) to name the options
function ui_codebasedMenu() {
  if [[ $# -eq 3 ]]; then
    declare -A codeMap
    local entries="$1[@]"
    local returnCodes=$2
    local -n __CODED_SELECTION__=$3
    local codes=({0..9} {a..z} {A..Z})
    local pos=0 startingPos=0 id=0 xShift=0 maxColumn=0
    local input=""
    terminal_getCursorLine startingPos
    pos=$((startingPos + 1))
    for entry in ${!entries}; do
      tput cup "$pos" "$xShift"
      value="${codes[$id]} -- $entry "
      codeMap["${codes[$id]}"]="$entry"
      echo "$value"
      pos=$((++pos))
      id=$((++id))
      if [[ $pos -gt $(($(tput lines) - 3)) ]]; then
        xShift=$((xShift + maxColumn))
        pos=$((startingPos + 1))
      fi
      math_max "$maxColumn" "${#value}" maxColumn
    done
    tput cup "$(($(tput lines) -2))" 0
    read -rp "> " input
    if [[ $returnCodes == true ]]; then
      __CODED_SELECTION__="$input"
    else
      __CODED_SELECTION__=()
      for ((charId=0; charId < ${#input}; ++charId)); do
        __CODED_SELECTION__+=("${codeMap[${input:$charId:1}]}")
      done
    fi
    unset codeMap
  else
    bashlib_abort "$(caller)" "[&options] [result selection (T/F)] [&result]"
  fi
}

# This function prints a nice-looking interactive menu with boolean selection entries (true/false) that is fully usable with arrow keys, the mouse and can
# have a built-in 'help' message for each available option
# arg0: The name of the array containing the list of available options
# arg1: The name of the array containing the option status (array of bool, will be updated at the end with the selection of the user but can already contains
#   some true/false pre-selection)
# arg2: (optional) The name of the array containing the 'help' (a short message) about the available options
# Example:
#   array=(option1 option2 option3)
#   state=(false false false)
#   help=("This is option 1" "Choose this for option 2" "That's option 3 !")
#   ui_booleanMenu array result help
#   if [[ ${result[2]} == true ]]; then
#     echo "The user selected the option ${array[2]} !"
#   fi
# Note:
#   The menu can be used with the arrow keys (jumping from left/right/top/down option), space or enter is used to toggle the current option or with the mouse.
#   A left click will toggle the option while a right click will toggle the 'help' message if any, entering '?' will also toggle the 'help' in case it exists
function ui_booleanMenu() {
  if [[ $# -ge 2 ]]; then
    declare -A optionMap optionState idMap choiceMap
    local entries="$1[@]"
    local -n __BOOL_MENU_STATE__=$2
    if [[ $# -eq  3 ]]; then
      local -n optionMsg=$3
    else
      optionMsg=()
    fi
    local columnSizes=(0) choices=() rowCol=()
    local topRow=0 maxRow=0 maxCol=0 xShift=0 row=0 col=0 size=0 xPos=0 count=0 posX=0 posY=0 width=0 temporaryValue=0
    local space="" value="" key="" eventValue="" eventType=""
    terminal_getCursorLine topRow
    row=$topRow
    maxRow=$(($(tput lines) - 4))
    # First loop over the entries to create the map (<row,col>;entry), (<row,col>;state) and (<row,col>; id); it counts as well the max length of each column
    for entry in "${!entries}"; do
      value="$(printf "%02d" ${#optionMap[@]}) $entry"
      key="$row;$col"
      optionMap[$key]="$value"
      optionState[$key]=${__BOOL_MENU_STATE__[$count]}
      idMap[$key]=$count
      choiceMap[$key]=${optionMsg[$count]}
      math_max "${columnSizes[$col]}" "${#value}" temporaryValue
      # shellcheck disable=2004
      columnSizes[$col]=$temporaryValue
      row=$((++row))
      count=$((++count))
      if [[ $row -ge $maxRow ]]; then
        row=$topRow
        col=$((++col))
        columnSizes+=(0)
      fi
    done
    # Initial print of all the entries based on their position and initial state
    for value in "${!optionMap[@]}"; do
      string_tokenize "$value" ";" rowCol
      xShift=0
      for ((index=1; index <= rowCol[1]; ++index)); do
        xShift=$((xShift + ${columnSizes[$((index - 1))]} + 5))
      done
      tput cup "$((rowCol[0] + 1))" "$xShift"
      space=$(printf "%-$((columnSizes[rowCol[1]] - ${#optionMap[$value]} + 1))s" " ")
      if [[ ${optionState[$value]} == false ]]; then
        echo "${optionMap[$value]}${space// / }[ ]"
      else
        string_echoRich "~A${optionMap[$value]}${space// / }[X]~"
      fi
    done
    tput civis
    [[ $col -eq 0 ]] && maxRow=$((${#optionMap[@]} + topRow))
    row=$maxRow
    col=0
    # Add a 'confirm' button at the bottom of the menu
    ui_centerTopLeft 7 1 xPos _
    tput cup "$((maxRow + 1))" "$xPos"
    tput sc
    string_echoRich "*Confirm*"
    tput rc
    # Main menu, react to every key press and redraw only the changed/selected options
    while true; do
      terminal_readEvent eventValue eventType
      # Unselect the current option (displayed in bold)
      if [[ $row -ne $maxRow ]]; then
        xShift=0
        for ((index=1; index <= col; ++index)); do
          xShift=$((xShift + ${columnSizes[$((index - 1))]} + 5))
        done
        tput cup "$((row + 1))" "$xShift"
        value="$row;$col"
        space=$(printf "%-$((columnSizes[col] - ${#optionMap[$value]} + 1))s" " ")
        if [[ ${optionState[$value]} == false ]]; then
          echo "${optionMap[$value]}${space// / }[ ]"
        else
          string_echoRich "~A${optionMap[$value]}${space// / }[X]~"
        fi
      else
        tput cup "$((maxRow + 1))" "$xPos"
        echo "Confirm"
      fi
      # Compute which is the new current option
      if [[ "$eventType" == "arrow" ]]; then
        case "$eventValue" in
          UP)
            if [[ $row -eq $topRow ]]; then
              row=$maxRow
            else
              row=$((--row))
              while [[ ! ${optionMap["$row;$col"]} ]]; do
                row=$((--row))
              done
            fi;;
          DOWN)
            if [[ $row -eq $maxRow ]]; then
              row=$topRow
            else
              row=$((++row))
              if [[ ! ${optionMap["$row;$col"]} ]]; then
                row=$maxRow;
              fi
            fi;;
          LEFT) [[ $col -eq 0 ]] && col=$((${#columnSizes[@]} - 1)) || col=$((--col))
            while [[ ! ${optionMap["$row;$col"]} ]]; do
              row=$((--row))
            done;;
          RIGHT) [[ $col -eq $((${#columnSizes[@]} - 1)) ]] && col=0 || col=$((++col))
            while [[ ! ${optionMap["$row;$col"]} ]]; do
              row=$((--row))
            done;;
        esac
      elif [[ "$eventType" == "validation" ]]; then
        if [[ $row -eq $maxRow ]]; then
          break
        else
          if [[ ${optionState["$row;$col"]} == true ]]; then
            optionState["$row;$col"]=false;
            __BOOL_MENU_STATE__[${idMap["$row;$col"]}]=false
          else
            optionState["$row;$col"]=true;
            __BOOL_MENU_STATE__[${idMap["$row;$col"]}]=true
          fi
        fi
      elif [[ "$eventType" == "key" ]]; then
        if [[ "$eventValue" == "?" ]]; then
          if [[ ${choiceMap["$row;$col"]} ]]; then
            math_min "$(tput cols)" 50 width
            ui_centerTopLeft "$width" "$((${#choiceMap["$row;$col"]} / 50 + 2))" posX posY
            ui_okWindow "$posX" "$posY" "$width" "${choiceMap["$row;$col"]}" true
          fi
        fi
      elif [[ "$eventType" == "mouse" ]]; then
        string_tokenize "$eventValue" ";" rowCol
        if [[ ${rowCol[0]} =~ ^[0-9]+$ ]] && [[ ${rowCol[1]} =~ ^[0-9]+$ ]] && [[ ${rowCol[2]} =~ ^[0-9]+$ ]]; then
          posX=0
          posY=$((rowCol[2] - 1))
          for ((index=0; index < ${#columnSizes[@]}; ++index)); do
            if [[ $((posX + ${columnSizes[$index]} + 5)) -gt ${rowCol[1]} ]]; then
              posX=$index
              break
            else
              posX=$((posX + ${columnSizes[$index]} + 5))
            fi
          done
          math_min "$posX" "$((${#columnSizes[@]} - 1))" posX
          math_max "$((posY - 1))" 0 row
          col=$posX
          value="$row;$col"
          while [[ ! ${optionMap["$row;$col"]} ]]; do
            row=$((--row))
          done
          if [[ "${rowCol[0]}" == "0" ]]; then
            if [[ ${optionState["$value"]} == true ]]; then
              optionState["$value"]=false;
              __BOOL_MENU_STATE__[${idMap["$value"]}]=false
            else
              optionState["$value"]=true;
              __BOOL_MENU_STATE__[${idMap["$value"]}]=true
            fi
          elif [[ "${rowCol[0]}" == "2" ]]; then
            if [[ ${choiceMap["$value"]} ]]; then
              math_min "$(tput cols)" 50 width
              ui_centerTopLeft "$width" "$((${#choiceMap["$value"]} / 50 + 2))" posX posY
              ui_okWindow "$posX" "$posY" "$width" "${choiceMap["$value"]}" true
            fi
          fi
        fi
      fi
      # Update the new current option (in bold or apply the change of state)
      if [[ $row -ne $maxRow ]]; then
        xShift=0
        for ((index=1; index <= col; ++index)); do
          xShift=$((xShift + ${columnSizes[$((index - 1))]} + 5))
        done
        tput cup "$((row + 1))" "$xShift"
        value="$row;$col"
        space=$(printf "%-$((columnSizes[col] - ${#optionMap[$value]} + 1))s" " ")
        if [[ ${optionState[$value]} == false ]]; then
          string_echoRich "*${optionMap[$value]}${space// / }[ ]*"
        else
          string_echoRich "*~A${optionMap[$value]}${space// / }[X]~*"
        fi
      else
        tput cup "$((maxRow + 1))" "$xPos"
        string_echoRich "*Confirm*"
      fi
    done
    tput cvvis
    unset optionState optionMap idMap choiceMap
  else
    bashlib_abort "$(caller)" "[&options] [&states] {&options description}"
  fi
}

# This function creates and displays a waiting bar that can then be updated during the main process using waitbarUpdate, the waitbar will be a thread running
# in background without using CPU (but required inotify-tools package) and that can be trigger to update it's display by any other thread
# arg0: The X position of the waitbar
# arg1: The Y position of the waitbar
# arg2: The width of the waitbar
# arg3: The name of the variable that will contain the result (waitbar object)
# Note:
#   The waitbar will adapt its graphics to the width and will expect a percentage value (empty being 0 and full being 100), see ui_waitbarUpdate for more info.
#   When reaching a percentage of 100 the thread will kill itself automatically (the waitbar is not designed to go to a percentage lower than one previously
#   set despite this would be easy to change if required)
#@DEPENDS: inotify-tools
function ui_waitbarCreate() {
  if [[ $# -eq 4 ]]; then
    local -n __WAITBAR_INSTANCE__=$4
    local dataExch="/tmp/$RANDOM"
    local waitbarObject=""
    threads_create waitbarObject << THREAD
xPosition=$1
yPosition=$2
width=$3
percentage=0
lastPercentage=0
position=\$((xPosition+1))
if [[ \$width -gt \$(tput cols) ]]; then
  width=\$(tput cols)
fi
loadingBar=\$(printf "%-\$((width))s" " ")
tput sc
tput cup \$yPosition \$xPosition
echo -e "[${COLOR_FG_GRAY}\${loadingBar// /▒}${COLOR_RESET}]"
tput rc
mkdir "$dataExch"
while [[ \$running == true ]]; do
  res=\$(inotifywait -e create $dataExch 2>/dev/null)
  file=\${res#?*CREATE }
  percentage=\$(cat $dataExch/\$file 2>/dev/null)
  [[ \$percentage -gt 100 ]] && percentage=100 && running=false
  if [[ \$percentage -gt \$lastPercentage ]]; then
    lastPercentage=\$percentage
    percentage=\$((percentage * width / 100))
    loadingBar=\$(printf "%-\$((percentage))s" " ")
    tput sc
    tput cup \$yPosition \$((xPosition + 1))
    echo -e "${COLOR_FG_GREEN}\${loadingBar// /▒}${COLOR_RESET}"
    tput rc
    rm -f "$dataExch/\$file"
  fi
done
rm -r "$dataExch"
THREAD
    threads_run "$waitbarObject"
    __WAITBAR_INSTANCE__="$waitbarObject:$dataExch"
  else
    bashlib_abort "$(caller)" "[x position] [y position] [width] [&waitbar]"
  fi
}

# This function will update the completion of the waitbar on the screen
# arg0: The waitbar object previously created using ui_waitbarCreate
# arg1: The new percentage of completion [0-100]
# Note:
#   Be aware than drawing this update will need to tput the cursor somewhere else on the screen, it would be a good idea, as this is done asynchronously, to
#   have a lock preventing other running threads playing with the cursor to do so during the update of the waitbar
function ui_waitbarUpdate() {
  if [[ $# -eq 2 ]]; then
    string_tokenize "$1" ":" tokens
    if [[ ${#tokens[@]} -eq 2 ]]; then
      echo "$2" 2>/dev/null > "${tokens[1]}/data"
    else
      bashlib_abort "$(caller)" "[waitbar] [new percentage]"
    fi
  else
    bashlib_abort "$(caller)" "[waitbar] [new percentage]"
  fi
}

# This function will delete the thread handling the waitbar, should be called during cleanup otherwise the thread will be left forever in the thread pool and in
# the system if the waitbar never reached 100%
# arg0: The waitbar object to delete
function ui_waitbarDelete() {
  if [[ $# -eq 1 ]]; then
    string_tokenize "$1" ":" tokens
    threads_kill "${tokens[0]}" "9"
    threads_join "${tokens[0]}"
    rm -r "${tokens[1]}" &>/dev/null
  else
    bashlib_abort "$(caller)" "[waitbar]"
  fi
}
