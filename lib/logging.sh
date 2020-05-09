#@PRIORITY: 1
function log_open() {
  if [[ $# -ne 1 ]]; then
    false
  else
    __IS_LOG_OPEN__=true
    exec {log_pid}>>$1
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
    local timestamp=$(date +%Y-%m-%d:\ %H:%M:%S)
    local line=$(caller | awk '{print $1}')
    local from=$(caller | awk '{print $2}')
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
