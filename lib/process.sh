
# Closes all the "non-default" file descriptors the CURRENT process has open or inherited from its parent
function process_closeAllFileDescriptors() {
  # shellcheck disable=SC2044
  for fd in $(find /proc/$$/fd -type l -printf "%f\n"); do
    # stdin (0), stdout (1), stderr(2) and the TTY connection (255 depending on the distribution) will NOT be closed
    if [[ $fd -gt 2 ]] && [[ $fd -ne 255 ]]; then
      eval "exec $fd>&-"
    fi
  done
}
