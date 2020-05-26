#@PRIORITY: 1
function log_open() {
  if [[ $# -ne 1 ]]; then
    false
  else
    __IS_LOG_OPEN__=true
    exec {log_pid}>>"$1"
    # pre-4.1 eval "exec $pid>>$filename"
  fi
}

function log_close() {
  __IS_LOG_OPEN__=false
  exec {log_pid}<&-
  # pre-4.1 eval "exec $pid>&-"
}

# log_write "test"
# command | log_write
# command 2>&1 >/dev/null | log_write -> print only error msg
function log_write() {
  if [[ $# -lt 1 ]]; then
    false
  else
    local timestamp=""
    local line=""
    local from=""
    timestamp=$(date +%Y-%m-%d:\ %H:%M:%S)
    line=$(caller | awk '{print $1}')
    from=$(caller | awk '{print $2}')
    if [[ -n "$1" ]]; then
      echo -e "[$timestamp] ($from:$line) $1" >&${log_pid}
    else
      local inputLine=""
      while read -r inputLine; do
        echo -e "[$timestamp] ($from:$line) $inputLine" >&${log_pid}
      done
    fi
  fi
  # pre-4.1 eval "echo $1 >&$pid"
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
