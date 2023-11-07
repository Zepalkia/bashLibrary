#@PRIORITY: 8
source string.sh
source math.sh
# WebSocket Protocol definition (standard):
#   https://www.rfc-editor.org/rfc/rfc6455
#
# Be aware that this implementation is compatible with payloads of size up to 65535 bits, it could be expanded to 64bits using
# the definition for such payload in the standards if required to transmit more data


# Prepares the Header required to send a given payload to a remote server through a WebSocket
# arg0: The message one wants to encode & send
# arg1: The name of the variable that will contain the header
function websocket_buildHeader() {
  if [[ $# -eq 2 ]]; then
    local -n __WS_HEADER=$2
    local payloadLength=""
    # \x81 --> 129 in decimal --> 10000001 in binary which sets the start of the header flags to:
    #   FIN: 1 (unique message)
    #   RSV1: 0
    #   RSV2: 0
    #   RSV3: 0
    #   opcode [0-3]: 1 (text frame)
    #
    # \xFE --> 254 in decimal --> 11111110 in binary which sets the next part of the header to:
    #   MASK: 1 (the payload will be masked)
    #   Payload len: 126 (defines that the next 2 byte will contain the payload len encoded as an unsigned 16bits integer)
    #
    # decToHex2 --> Will return the length of the payload encoded into the 2 byte format we want to use
    #
    # /!\ Due to using this encoding the max payload size is 65535, in order to have a bigger one (up to 64bits unsigned of size) please check the RFC6455
    # standard to define a bigger size
    math_decToHex "${#1}" 2 payloadLength
    __WS_HEADER="\x81\xFE$payloadLength"
  else
    bashlib_abort "$(caller)" "[message to send] [&header]"
  fi
}

# Applies a given mask to a given message following RFC6455 definitions
# arg1: The message one wants to encode & send
# arg2: The mask to use to encode the payload
# arg3: The name of the variable that will contain the masked message
function websocket_applyMask() {
  if [[ $# -eq 3 ]]; then
    local message=$1
    local key=$2
    local -n __WS_MASKED=$3
    local index=0
    for ((; index < ${#message}; ++index)); do
      local value=$(($index % ${#key}))
      local char=${message:$index:1}
      local keyChar=${key:$value:1}
      local messageByte=""
      local keyByte=""
      local finalChar=""
      math_byteToInt "$char" messageByte
      math_byteToInt "$keyChar" keyByte
      math_decToHex $((messageByte ^ keyByte)) 1 finalChar
      __WS_MASKED="$__WS_MASKED$finalChar"
    done
  else
    bashlib_abort "$(caller)" "[message to send] [mask to apply] [&masked message]"
  fi
}

# Performs the initial WebSocket Handshake following RFC6455 standards using the given FileDescriptor
# arg0: The already-open socket filescriptor
# return: 0 if successful, 1 otherwise
function websocket_performHandshake() {
  local result=1
  if [[ $# -eq 1 ]]; then
    local __WEBSOCKET=$1
    echo "GET / HTTP/1.1
Host: $host:$port
Origin: http://$host:$port
Connection: Upgrade
Upgrade: websocket
Sec-WebSocket-Key: $(openssl rand -base64 16)
Sec-WebSocket-Version: 13
" >&$__WEBSOCKET
    # The remote should send the '101 protocol upgrade payload' back in a line-by-line way, here we just parse it with a max timeout of 2 sec. to stop once
    # we received everything (everything has to be consumed now)
    while read -t2 <&$__WEBSOCKET; do
      case "$REPLY" in
        Connection*) [[ "$REPLY" =~ "Upgrade" ]] && result=0;;
      esac
    done
  else
    bashlib_abort "$(caller)" "[fd of the socket]"
  fi
  return $result
}

# Sends a given payload through a previously created WebSocket to the remote and wait (blocking) until a reply is received
# arg0: The socket generated by the 'websocket_create' function
# arg1: The payload to send
# arg2: The name of the variable that will contain the reply from the remote
function websocket_sendRecv() {
  if [[ $# -eq 3 ]]; then
    local __WEBSOCKET=""
    local msg=$2
    local __WS_REPLY=$3
    local mask=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 4)
    local header=""
    local masked=""
    string_tokenize "$1" ":" __WEBSOCKET
    # Generates the header and masks the payload following the standards
    websocket_buildHeader "$msg" header
    websocket_applyMask "$msg" "$mask" masked
    # Cleanup the WS buffer
    echo "" >${__WEBSOCKET[1]}
    echo -e -n "$header$mask$masked" >&${__WEBSOCKET[0]}
    __WS_REPLY=""
    # Wait until the WS buffer has some readable data in it
    while [[ "$__WS_REPLY" == "" ]]; do
      sleep 1
      read __WS_REPLY <"${__WEBSOCKET[1]}"
    done
  else
    bashlib_abort "$(caller)" "[websocket] [message to send] [&reply]"
  fi
}

# Creates a new WebSocket connected to a given host/port, the socket will be available as a regular file descriptor for the process
# arg0: The host (ip or DNS-resolvable address) server
# arg1: The connection port
# arg2: The name of the variable that will contain the generated WS (if successful, will be an empty string otherwise)
function websocket_create() {
  if [[ $# -eq 3 ]]; then
    local __BL_WS_FD=0
    local -n __WEBSOCKET=$3
    # This is bash-only, if you're reading this wondering what the hell it means as it doesn't work for you you may need to adapt
    # it to your shell.
    # It can be translated as 'open a R/W file descriptor as a socket and connect it to host:port'.
    # The /dev/tcp "file" is only available in bash, probably not in other shells as it isn't POSIX at all
    # The {__BS_WS_FD} part is only available in bash starting v4.1 so older releases will not be able to run this, the point of
    # this syntax is to automatically assign the next free file descriptor to the variable without having to manually specify one.
    exec {__BL_WS_FD}<>/dev/tcp/$1/$2
    # Performs the handshake to validate the socket is properly connected to a websocket server
    if websocket_performHandshake $__BL_WS_FD; then
      __WEBSOCKET="$__BL_WS_FD:/dev/shm/$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 20)"
      while read -d $'\0' <&$__BL_WS_FD; do
        echo "$REPLY" >$__WEBSOCKET["buffer"]
      done &>/dev/null &
      __WEBSOCKET="$__WEBSOCKET:$!"
    else
      # In case of failure the fd is immediately closed
      __WEBSOCKET=""
      exec {__BL_WS_FD}<&-
    fi
  else
    bashlib_abort "$(caller)" "[server address] [server port] [&websocket]"
  fi
}

# Closes a websocket previously created by the 'websocket_create' function
# arg0: The websocket to close
function websocket_close() {
  if [[ $# -eq 1 ]]; then
    local __WEBSOCKET=""
    string_tokenize "$1" ":" __WEBSOCKET
    local fd=${__WEBSOCKET[0]}
    exec {fd}<&-
    [[ -f ${__WEBSOCKET[1]} ]] && rm ${__WEBSOCKET[1]}
    [[ ${__WEBSOCKET[w]} != "" ]] && kill ${__WEBSOCKET[2]} 2>/dev/null
  else
    bashlib_abort "$(caller)" "[websocket]"
  fi
}
