#@PRIORITY: 0
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
    if inotifywait "/tmp/.bashLock" &>/dev/null; then
      touch "/tmp/.bashLock/$$"
      success=true
    else
      inotifywait -e delete --quiet "/tmp/.bashLock"
    fi
  done
}

# This function tries to create a unique global lock that will prevent any other process to use it until lockable_globalUnlock is called by it
# arg0: The max time (in seconds) we want to try to lock
# Example:
#   if lockable_globalTryLock 5; then
#     echo "I am now free of doing thread-safe stuff !"
#     lockable_globalUnlock
#   else
#     echo "Impossible to secure the lock, another process is already using it"
#   fi
# Note:
#   This function doesn't depend on any other package and will try twice a second to secure the lock until the asked time is reached or until a success
#   In case the lock is already in use for the whole time the process will NOT be secure, the result value has to be checked to react properly to it's value
function lockable_globalTryLock() {
  local __TRYLOCK_SUCCESS__=1
  if [[ $# -eq 1 ]]; then
    local timeStart=0
    local success=false
    timeStart=$(date +%s)
    # check $1 is an int !
    while [[ $success == false ]] && [[ $(($(date +%s) - timeStart)) -lt $1 ]]; do
      if mkdir "/tmp/.bashLock" &>/dev/null; then
        touch "/tmp/.bashLock/$$"
        success=true
        __TRYLOCK_SUCCESS__=0
      else
        sleep .5
      fi
    done
  else
    bashlib_abort "$(caller)" "[attempt time]"
  fi
  return $__TRYLOCK_SUCCESS__
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
    lockfile=$(basename_ /tmp/.bashLock/*)
    if [[ $(ps_ -p "$lockfile" | wc -l) -le 1 ]]; then
      rm -f "/tmp/.bashLock/$lockfile"
      rmdir /tmp/.bashLock
    fi
  fi
}

# This function creates a scope-function lock that will prevent any other process to call it until lockable_scopeUnlock is called by the initial process
# Example:
#   foo() {
#     lockable_scopeLock
#     echo "No one is able to call this function now !!"
#     ...
# Note:
#   This function is fully blocking, it will not go ahead until the lock has been created successfully. For making it efficient it depends on 'inotify-tools'
# If you don't want to install this package or if you prefer a non-blocking way of locking a scope, see 'lockable_scopeTryLock'
#@DEPENDS: inotify-tools
function lockable_scopeLock() {
  local success=false
  local lockName="/tmp/.lock_${FUNCNAME[1]}"
  while [[ $success == false ]]; do
    if mkdir "$lockName" &>/dev/null; then
      touch "$lockName/$$"
      success=true
    else
      inotifywait -e delete --quiet "$lockName"
    fi
  done
}

# This function tries to create a function-scope lock that will prevent any other process to use it until lockable_scopeUnlock is called
# arg0: The max time (in seconds) we want to try to lock
# Example:
#   foo() {
#     if lockable_scopeTryLock 5; then
#       echo "Foo is now locked !"
#       lockable_scopeUnlock
#     else
#       echo "Someone is already using 'foo()', impossible to secure it !"
#     fi
# Note:
#   This function doesn't depend on any other package and will try twice a second to secure the lock until the asked time is reached or until a success.
#   In case the lock is already in use for the whole time the process will NOT be secure, the result value has to be checked to react properly to the result.
#   See 'lockable_scopeLock' to have a blocking and efficient way of doing the same thing using inotify package
function lockable_scopeTryLock() {
  local __SCOPE_TRYLOCK_SUCCESS__=1
  if [[ $# -eq 1 ]]; then
    local timeStart=0
    local success=false
    local lockName="/tmp/.lock_${FUNCNAME[1]}"
    timeStart=$(date +%s)
    while [[ $success == false ]] && [[ $(($(date +%s) - timeStart)) -lt 1 ]]; do
      if mkdir "$lockName" &>/dev/null; then
        touch "$lockName/$$"
        success=true
        __SCOPE_TRYLOCK_SUCCESS__=0
      else
        sleep .5
      fi
    done
  else
    bashlib_abort "$(caller)" "[attempt time]"
  fi
  return $__SCOPE_TRYLOCK_SUCCESS__
}

# This function unlocks the scope lock created by a previous scopeLock/scopeTryLock call
# Example:
#   lockable_scopeUnlock
#   echo "Another process can now grab the lock, the following steps are not thread-safe anymore"
# Note:
#   The same process is expected to run the lock AND the unlock, scopeUnlock() will also work in case a process that locked the scope is not active anymore but
#   this is only a 'security' check that should never be triggered if the process has been designed properly
function lockable_scopeUnlock() {
  local lockFile=""
  local lockName="/tmp/.lock_${FUNCNAME[1]}"
  lockFile=$(find "$lockName" -name "$$")
  if [[ "$lockFile" != "" ]]; then
    rm -f "$lockFile"
    rmdir "$lockName"
  else
    lockFile=$(basename "$lockName/*")
    if [[ $(ps -p "$lockFile" | wc -l) -le 1 ]]; then
      rm -f "$lockName/$lockFile"
      rmdir "$lockName"
    fi
  fi
}
