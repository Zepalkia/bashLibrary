source utilities.sh
source threads.sh

# This function creates and launch a thread that will provides timing mechanism
# arg0: The name of the variable that will contain the timer object
function timer_create() {
  if [[ $# -eq 1 ]]; then
    local -n __TIMER_INSTANCE__=$1
    local timerObject=""
    threads_create timerObject << THREAD
startTime=0
window=0
file=/tmp/\$RANDOM
exec 5<>\$file
rm -f \$file
function reset() {
  startTime=\$(date +%s)
}
function dump() {
  echo "\$((\$(date +%s) - startTime))" >&5
}
function startWindow() {
  window=\$(date +%s)
}
trap reset 35
trap dump 36
reset
while [[ \$running == true ]]; do
  utilities_interruptableSleep 1
done
exec >&5-
THREAD
    threads_injectFunction "$timerObject" "utilities_interruptableSleep"
    threads_run "$timerObject"
    __TIMER_INSTANCE__="$timerObject"
  else
    bashlib_abort "$(caller)" "[&timer]"
  fi
}

# This function resets the timer back to 0
# arg0: The timer object to reset
function timer_reset() {
  if [[ $# -eq 1 ]]; then
    threads_notify "$1" "35"
  else
    bashlib_abort "$(caller)" "[timer]"
  fi
}

# This function retrieves the current value of a given timer (the number of seconds since last resets/creation)
# arg0: The timer object
# arg1: The name of the variable that will contain the value
function timer_getValue() {
  if [[ $# -eq 2 ]] && [[ ${__BL_THREAD_POOL__["$1"]} ]]; then
    local -n __TIMER_VALUE__=$2
    lastValue=$(tail -1 /proc/${__BL_THREAD_POOL__["$1"]}/fd/5)
    threads_notify "$1" "36"
    sleep .1
    __TIMER_VALUE__=$(tail -1 /proc/${__BL_THREAD_POOL__["$1"]}/fd/5)
  else
    bashlib_abort "$(caller)" "[timer] [&result]"
  fi
}

# This function stops and deletes a timer object
# arg0: The timer object to delete
function timer_delete() {
  if [[ $# -eq 1 ]]; then
    threads_kill "$1"
    threads_delete "$1"
  else
    bashlib_abort "$(caller)" "[timer]"
  fi
}

