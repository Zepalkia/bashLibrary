#@PRIORITY: 2
source string.sh
source lockable.sh
# Here's a global example showing how the following functions can be used altogether
# Global example:
# ------------------------------------
# function waitSeconds() {
#   sleep "$1"
# }
# threads_create thread0 << THREAD
#count=0
#while [[ \$running == true ]]; do
#  count=\$((++count))
#  touch /tmp/"\$count"
#  waitSeconds 7
#done
#THREAD
#
# threads_injectFunction "$thread0" "waitSeconds"
# threads_run "$thread0"
# waitSeconds 60
# threads_kill "$thread0"
# threads_join "$thread0"
# -----------------------------------
# In this example we can see how to define a thread that creates a new file in /tmp every 7 seconds, we let it run for 60 seconds before asking it to stop.
# In this case as 'kill' is called without any parameter and the thread is looping using the internal 'running' boolean the thread will exit properly after
# having finished the full iteration.
# By using threads_kill "$thread0" "9" the thread would have been killed immediatly with -9 (SIGKILL), and the thread can be relaunched as many time as required
# as long threads_delete is not called.
# This allow to easily creates background piece of codes in a more readable way with some sort of "smartness" in the killing and handling process, we can also
# see here how easy it becomes to inject already-defined functions inside the thread without having to re-define them


# This function creates a new thread ready to be launched and handled by the following functions
# arg0: The name of the variable that will contain the defined thread
# Example: See above
# Note:
# The thread will automatically handle a variable called 'running' that will be toggled to false once the threads_kill() function has been triggered without
# specifying any signal, therefore if the generated thread is suppose to run forever until 'kill' is called, "while [[ $running == true ]]" can be used
# in the thread definition and will loop until threads_kill is called and will assure that the ongoing loop will end properly (not abruptly like with a SIGINT
# or SIGKILL for example)
function threads_create() {
  if [[ $# -eq 1 ]]; then
    local randomStr=""
    local tmpFile=""
    local -n __THREAD_ID__=$1
    string_rand "0-9A-Z" 10 randomStr
    tmpFile="/tmp/.$randomStr"
    cat > "$tmpFile" << EOF
function killRequired() {
  running=false
}
trap killRequired USR1
running=true
EOF
    while read -r inputLine; do
      echo "$inputLine" >> "$tmpFile"
    done
    __THREAD_ID__=$randomStr
  else
    bashlib_abort "$(caller)" "[&thread]"
  fi
}

# This function launches a previously created thread an add it into the global thread pool handled by bashLibrary
# arg0: The thread created previously by threads_create()
# Example: See above
function threads_run() {
  local __BL_THREAD_LAUNCHED__=1
  if [[ $# -eq 1 ]]; then
    if [[ -f "/tmp/.$1" ]]; then
      (source "/tmp/.$1") &
      __BL_THREAD_POOL__["$1"]=$!
      __BL_THREAD_LAUNCHED__=0
    fi
  else
    bashlib_abort "$(caller)" "[thread]"
  fi
  return $__BL_THREAD_LAUNCHED__
}

# This function join a running thread or, if the thread isn't running, will go ahead doing nothing
# arg0: The thread created&launched previously using threads_create() and threads_run()
# Example: See above
# Note:
#  The behaviour of a 'join' is fully blocking, a call to this function will not go ahead until the thread ended, it's required to call threads_kill() BEFORE in
#  case the running thread is a forever-running one
#  To join in a non-blocking wait for a given amount of time see 'threads_tryJoin'
function threads_join() {
  local __BL_THREAD_JOINED__=1
  if [[ $# -eq 1 ]]; then
    if [[ ${__BL_THREAD_POOL__["$1"]} ]]; then
      wait "${__BL_THREAD_POOL__["$1"]}" &>/dev/null
      __BL_THREAD_JOINED__=0
    fi
  else
    bashlib_abort "$(caller)" "[thread]"
  fi
  return $__BL_THREAD_JOINED__
}

# This function will try to join a thread for a given amount of time and, in case of success or failure, will go ahead returning the result
# arg0: The thread created&launched previously using threads_create() and threads_run()
# arg1: The amount of time (in seconds) we expect to wait
# return: 0 if the thread has been joined successfully, 1 otherwise
# Example: See above
# Note:
#  This function is fully blocking only for the given amount of time, it will check every 500ms if the thread is still running or not and in the end the return
#  value has to be checked to know in which situation we are after the join
function threads_tryJoin() {
  local __BL_THREAD_TRY_JOINED__=1
  if [[ $# -eq 2 ]]; then
    if [[ ${__BL_THREAD_POOL__["$1"]} ]]; then
      timeStart=$(date +%s)
      while system_isProcessRunning "${__BL_THREAD_POOL__["$1"]}" && [[ $(($(date +%s) - timeStart)) -lt $2 ]]; do
        sleep .5
      done
      if ! system_isProcessRunning "${__BL_THREAD_POOL__["$1"]}"; then
        __BL_THREAD_TRY_JOINED__=0
      fi
    fi
  else
    bashlib_abort "$(caller)" "[thread] [attempt time]"
  fi
  return $__BL_THREAD_TRY_JOINED__
}

# This function will kill an already-running thread with a specific signal
# arg0: The thread to be killed
# arg1: (optional) The number/name of the signal to send to the thread (e.g. '9' or 'SIGKILL')
# return: 0 if the kill signal has been sent successfully, 1 otherwise
# Example: See above
# Note:
#  By default, the 'kill' will trigger a SIGUSR1 signal that will automatically togger a boolean variable named "running" to 'false', this makes very easy to
#  create thread running until the 'kill' is triggered by looping on this variable (e.g. while [[ $running == true ]]; do ...) and to be sure that the full
#  iteration will be performed before the thread will exit which will not be the case with stronger signal like SIGKILL
function threads_kill() {
  local __BL_THREAD_KILLED__=1
  if [[ $# -ge 1 ]]; then
    local cmd="kill"
    if [[ $# -eq 2 ]]; then
      cmd="$cmd -$2"
    else
      cmd="$cmd -USR1"
    fi
    if [[ ${__BL_THREAD_POOL__["$1"]} ]]; then
      cmd="$cmd ${__BL_THREAD_POOL__["$1"]}"
      $cmd &>/dev/null
    fi
    __BL_THREAD_KILLED__=0
  else
    bashlib_abort "$(caller)" "[thread] {signal (default: USR1)}"
  fi
  return $__BL_THREAD_KILLED__
}

# This function checks if a given thread is still running or not
# arg0: The thread to check
# return: 0 if the thread is running in the system, 1 otherwise
function threads_isRunning() {
  local __THREAD_IS_RUNNING__=1
  if [[ $# -eq 1 ]]; then
    if [[ ${__BL_THREAD_POOL__["$1"]} ]] && system_isProcessRunning "${__BL_THREAD_POOL__["$1"]}"; then
      __THREAD_IS_RUNNING__=0
    fi
  else
    bashlib_abort "$(caller)" "[thread]"
  fi
  return $__THREAD_IS_RUNNING__
}

# This function deletes a thread, this function should be called after a thread has been killed completely when cleaning up the system. Be aware than calling
# this function will prevent to run again the thread without re-creating it using threads_create
# arg0: The thread to delete permanently
# return: 0 if the thread was deleted properly, 1 otherwise (the thread was still running)
function threads_delete() {
  local __THREAD_DELETED__=1
  if [[ $# -eq 1 ]]; then
    if ! threads_isRunning "$1"; then
      rm -f "/tmp/.$1"
      __THREAD_DELETED__=0
    fi
  else
    bashlib_abort "$(caller)" "[thread]"
  fi
  return $__THREAD_DELETED__
}

# This function clears the bashLibrary thread pool by trying to kill, join and delete all of them. In case some threads are still running and cannot be joined in
# less than 2 seconds they will still be in the pool, there's not guarantee the pool will be completely empty after this call and threads could still be running
# if they cannot be killed
# arg0: A boolean that tells if we want to SIGKILL all the threads (true, default) or to just kill them properly (see threads_kill)
function threads_poolClear() {
  for thr in "${!__BL_THREAD_POOL__[@]}"; do
    if [[ $# -eq 1 ]] && [[ $1 == false ]]; then
      threads_kill "$thr"
    else
      threads_kill "$thr" "9"
    fi
    threads_tryJoin "$thr" 5
    if threads_delete "$thr"; then
      # shellcheck disable=SC2184
      unset __BL_THREAD_POOL__["$thr"]
    fi
  done
}

# This function injects a function declared in the launcher process inside the thread. This can be very handy to not have to manually copy-paste some part to
# add them inside the thread
# arg0: The thread in which to inject the function
# arg1: The name of the function
# return: 0 if the injection worked, 1 otherwise
# Example: See global example at top
function threads_injectFunction() {
  local __THREAD_INJECTION_SUCCESS__=1
  if [[ $# -eq 2 ]]; then
    if [[ "$(type -t "$2")" == "function" ]] && [[ -f "/tmp/.$1" ]]; then
      # shellcheck disable=SC2005
      # This 'echo' is required here to print the data we want (the body of the declared function)
      cat <(echo "$(declare -f "$2")") "/tmp/.$1" > "/tmp/.$1_2"
      mv "/tmp/.$1_2" "/tmp/.$1"
      __THREAD_INJECTION_SUCCESS__=0
    fi
  else
    bashlib_abort "$(caller)" "[thread] [function name]"
  fi
  return $__THREAD_INJECTION_SUCCESS__
}

# This function sends a specific signal to a given thread
# arg0: The thread to notify
# arg1: The signal number to send (e.g. "9" for SIGKILL)
function threads_notify() {
  if [[ $# -eq 2 ]]; then
    if [[ ${__BL_THREAD_POOL__["$1"]} ]]; then
      kill "-$2" "${__BL_THREAD_POOL__["$1"]}"
    fi
  else
    bashlib_abort "$(caller)" "[thread] [signal]"
  fi
}
