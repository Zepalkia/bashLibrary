#@PRIORITY: 8

# This function displays a given message followed by a spinner animation as long as a given process is running
# arg0: The message to display before the spinner
# arg1: The pid of the process this function should wait for
# Example:
#   (sleep 20)&
#   waiting_spinner "Waiting for sleep" $!
# Note:
#   The cursor final position will be on the same line as the message, cariage return will start from this line
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
    bashlib_abort "$(caller)" "${FUNCNAME[0]}" "[message] [pid]"
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
    bashlib_abort "$(caller)" "${FUNCNAME[0]}" "[pid]"
  fi
}

# This function display a given text in a single line and put back the cursor at the beginning, expected to be called while a background process is running
# Example:
#   waiting_textualSteps "Starting process..."
#   #do stuff
#   waiting_textualSteps "Step 2"
# Note:
#   The background stuff in-between should not output anything nor play with tput without putting back the cursor to it's initial state, this is expecting to be
#   manually triggered and to update all the time the same line
function waiting_textualSteps() {
  if [[ $# -eq 1 ]]; then
    echo -en "$1"
    tput el
    echo -en "\r"
  else
    bashlib_abort "$(caller)" "[text to display]"
  fi
}
