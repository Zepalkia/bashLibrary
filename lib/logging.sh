#@PRIORITY: 1

# This function opens a file descriptor pointing to the logfile path
# arg0: The path to the logfile (will not be erased but appended)
# Note:
#   This is only working with bash v4.1 and up, before the 'auto-fd' trick didn't exists and it was required to secure manually the file descriptor, e.g:
#   eval "exec $fd>>$filename"
#@VERSION: 4.1
function logging_open() {
  if [[ $# -eq 1 ]]; then
    exec {__BL_LOG_FD__}>>"$1"
  else
    bashlib_abort "$(caller)" "[logfile path]"
  fi
}

# This function closes the file descriptor of the logfile
# Note:
#   This is only working with bash v4.1 and up, before the 'auto-fd' trick didn't exists and it was required to secure manually the file descriptor, e.g:
#   eval "exec $fd<&-"
#@VERSION: 4.1
function logging_close() {
  __IS_LOG_OPEN__=false
  exec {__BL_LOG_FD__}<&-
}

# This function append a new line into the logfile opened using 'log_open', the implementation allows to use it in 3 different ways depending on the needs:
#   1. Direct call [log_write "..."] to append some specific string
#   2. Pipe redirection [command | log_write] to append all the output of the command
#   3. stderr redirection [command 2>&1 >/dev/null | log_write] to append only the error (if any)
# The function automatically prepend info about the log, i.e. the timestamp (date + hour/min/sec), the line from which the log has been called and the file name
# Example:
#   log_open
#   log_write "First log !"
#   git checkout master 2>&1 >/dev/null | log_write
#   log_close
# Note:
#   You can get rid of the 'log_open/log_close' calls if you don't want to use them by simply replacing the redirection done inside the 'echo' by the file you
#   want to use. To use it with log_open/log_close you'll need at least bash version 4.1 or modify the redirection to be compatible with pre-4.1:
#   eval "echo ... >&$fd"
#@VERSION: 4.1
function logging_write() {
  if [[ -n $__BL_LOG_FD__ ]]; then
    local timestamp=""
    local line=""
    local from=""
    timestamp=$(date +%Y-%m-%d:\ %H:%M:%S)
    line=$(caller | awk '{print $1}')
    from=$(caller | awk '{print $2}')
    if [[ -n "$1" ]]; then
      echo -e "[$timestamp] ($from:$line) $1" >&${__BL_LOG_FD__}
    else
      local inputLine=""
      while read -r inputLine; do
        echo -e "[$timestamp] ($from:$line) $inputLine" >&${__BL_LOG_FD__}
      done
    fi
  else
    bashlib_abort "$(caller) (log not opened)"
  fi
}

# This function enables the bash tracing that will list absolutely ALL bash calls done during runtime in a dedicated file. This is very helpful to debug the
# behaviour of bash scripts (gives line, file and timestamp with the variable resolving) but it can creates very huge files as well, this shouldn't be enabled
# all the time, only when really necessary
function logging_startTrace() {
  exec {BASH_XTRACEFD}>"/tmp/trace$(date +%s)"
  export PS4='- [$(basename $0):$LINENO--\t] '
  set -x
}

# This function disables the bash tracing, closes the file descriptor of the tracing file and revert back the 'PS4' value to the default one
function logging_stopTrace() {
  exec {BASH_XTRACEFD}<&-
  export PS4='+'
  set +x
}
