#@DEPENDENCIES: network-manager
source string.sh

#@DEPENDS: network-manager
function wifi_scan() {
  if [[ "$(nmcli radio wifi)" == "enabled" ]]; then
    local entries=()
    local tokens=()
    local line=""
    nmcli device wifi rescan 2>/dev/null
    sleep 5
    mapfile -t entries < <(nmcli -t --fields SSID,SIGNAL,SECURITY device wifi)
    for ((index=0; index < ${#entries[@]}; ++index)); do
      entries[$index]=${entries[$index]/ /_}
    done
    for line in "${entries[@]}"; do
      string_tokenize "$line" ":" tokens
    done
  else
    false
  fi
}
