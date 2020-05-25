#@PRIORITY: 8

# This function displays a given message followed by a spinner animation as long as a given process is running
# arg0: The message to display before the spinner
# arg1: The pid of the process this function should wait for
# Example:
#   (sleep 20)&
#   waiting_spinner "Waiting for sleep" $!
# Note:
#   The cursor final position will be on the same line as the message, \r will start from this line
#   otherwise you'll need to echo a newline to go to the next one and keep it.
#   This function is BLOCKING as long as the pid exists, by running it in background using & the
#   spinner animation will follow the cursor everyhere on the screen. If this is the behaviour you
#   want, try 'waiting_cursor' instead that does it automatically
function waiting_spinner() {
  if [[ $# -eq 2 ]]; then
    local steps=("|" "/" "─" "\\\\")
    # For terminals with compatible font, you can use the following 'braille' chars if available to have a
    # nice-looking spinner instead of the regular ascii chars
    # steps=("⠄" "⠆" "⠇" "⠋" "⠙" "⠸" "⠴" "⠤")
    local index=0
    echo -en "$1 "
    while [[ $(ps -p "$2" | wc -l) -eq 2 ]]; do
      echo -en "${steps[$index]}\b"
      index=$((++index % ${#steps[@]}))
      sleep 0.1
    done
  else
    bashlib_abort "$(caller)" "$FUNCNAME" "[message] [pid]"
    false
  fi
}

# This function adds a 'spinner' animation on the terminal's cursor as long as a given pid is running
# arg0: The pid of the process running in background
# Example:
#  (sleep 20)&
#  wating_cursor $!
function waiting_cursor() {
  if [[ $# -eq 1 ]]; then
    (waiting_spinner "" "$1") &
  else
    bashlib_abort "$(caller)" "$FUNCNAME" "[pid]"
  fi
}

function waiting_createWaitbar() {
  true
  echo "▒"
}

function waiting_stepWaitbar() {
  true
}
