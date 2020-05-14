#@DEPENDENCIES: inotify-tools

# This function creates a unique global lock that will prevent any other process to call it until lockable_globalUnlock is called by it
# Example:
#   lockable_globalLock
#   echo "I am now free of doing thread-safe stuff !"
# Note:
#   This function is fully blocking, it will not go ahead until the lock has been created successfully. For making it efficient it depends on 'inotify-tools'
#   package to be installed. If you don't want to have it or if you prefer a non-blocking way of locking a process, see lockable_globalTryLock
#@DEPENDS: inotify-tools
function lockable_globalLock() {
  local success=false
  while [[ $success == false ]]; do
    if mkdir "/tmp/.bashLock"; then
      touch "/tmp/.bashLock/$$"
      success=true
    else
      inotifywait -e delete --quiet "/tmp/.bashLock"
    fi
  done
}

# This function tries to create a unique global lock that will prevent any other process to use it until lockable_globalUnlock is called by it
# arg0: The max time (in seconds) we want to try to lock
# arg1: The name of the variable containing the result of the process (boolean)
# Example:
#   lockable_globalTryLock 5 result
#   if [[ $result == true ]]; then
#     echo "I am now free of doing thread-safe stuff !"
#     lockable_globalUnlock
#   else
#     echo "Impossible to secure the lock, another process is already using it"
#   fi
# Note:
#   This function doesn't depend on any other package and will try twice a second to secure the lock until the asked time is ready or until a success
#   In case the lock is already in use for the whole time the process will NOT be secure, the result value has to be checked to react properly to it's value
function lockable_globalTryLock() {
  if [[ $# -eq 2 ]]; then
    local -n __TRYLOCK_SUCCESS__=$2
    local timeStart=0
    local success=false
    timeStart=$(date +%s)
    # check $1 is an int !
    while [[ $success == false ]] && [[ $(($(date +%s) - timeStart)) -lt $1 ]]; do
      if mkdir "/tmp/.bashLock" &>/dev/null; then
        touch "/tmp/.bashLock/$$"
        success=true
      else
        sleep .5
      fi
    done
    __TRYLOCK_SUCCESS__=$success
  else
    false
  fi
}

# This function unlocks the global lock created by a previous globalLock/globalTryLock call
# Example:
#   lockable_globalUnlock
#   echo "Another process can now grab the lock, the following steps are not thread-safe anymore"
# Note:
#   The same process is expected to run the lock AND the unlock, globalUnlock() will work in case a process that called the lock is not active anymore but this
#   is only a 'security' patch that should actually never be triggered is the program using it has been designed properly
function lockable_globalUnlock() {
  local lockfile=""
  lockfile=$(find /tmp/.bashLock -name "$$")
  if [[ "$lockfile" != "" ]]; then
    rm -f "$lockfile"
    rmdir /tmp/.bashLock
  else
    lockfile=$(basename /tmp/.bashLock/*)
    if [[ $(ps -p "$lockfile" | wc -l) -le 1 ]]; then
      rm -f "/tmp/.bashLock/$lockfile"
      rmdir /tmp/.bashLock
    fi
  fi
}

