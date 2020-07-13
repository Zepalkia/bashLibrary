#@DEPENDENCIES: network-manager, isc-dhcp-server, iptables, aircrack-ng
source string.sh

# This function performs a scan of the wifi to retrieve the available networks (only their SSID)
# arg0: The name of the variable that will contain the found SSIDs (array)
#@DEPENDS: network-manager
function wifi_scan() {
  if [[ $# -eq 1 ]]; then
    local scanResult=""
    local -n __SSIDS_FOUND__=$1
    if [[ "$(nmcli radio wifi)" != "enabled" ]]; then
      nmcli radio wifi on 2>/dev/null
    fi
    nmcli device wifi rescan 2>/dev/null
    sleep 5
    mapfile -t __SSIDS_FOUND__ < <(nmcli -t --fields SSID device wifi)
  else
    bashlib_abort "$(caller)" "[&result]"
  fi
}

# This function retrieves the mac address of the main (or given) wifi interface
# arg0: The name of the wifi interface (optional, if not given will be searched automatically)
# arg1: The name of the variable that will contain the mac address (string)
# Example:
#   wifi_macAddress address
#   echo "The mac address of the main wifi interface is: $address"
#@DEPENDS: network-manager
function wifi_macAddress() {
  if [[ $# -eq 1 ]]; then
    local interface="";
    local -n __WIFI_MAC__=$1
    interface=$(nmcli device status | grep wifi | awk '{print $1}')
    __WIFI_MAC__=$(nmcli device show "$interface" | grep HWADDR | awk '{print $2}')
  elif [[ $# -eq 2 ]]; then
    local -n __WIF_MAC__=$2
    __WIFI_MAC=$(nmcli device show "$1" | grep HWADDR | awk '{print $2}')
  else
    bashlib_abort "$(caller)" "{wifi interface} [&result]"
  fi
}

# This function sets the parameters of the DHCP server to make it ready to give IPs as expected by a hotspot for example (see wifi_createHotspot).
# arg0: The signature IP (e.g. 192.168.1.0)
# arg1: The netmask (e.g. 255.255.255.0)
# arg2: The starting IP range (e.g. 192.168.1.100)
# arg3: The ending IP range (e.g. 192.168.1.150)
# arg4: The static IP of the interface that will provide IP addresses (e.g. 192.168.5.1)
# Example:
#   sudo -s
#   wifi_setupDHCP 60.0.0.0 255.255.255.0 60.0.0.100 60.0.0.200 60.0.0.1
#@DEPENDS: isc-dhcp-server
function wifi_setupDHCP() {
  if [[ $# -eq 5 ]]; then
    if [[ -w /etc/dhcp/dhcpd.conf ]]; then
      local bcastIP=${1//0/255}
      service isc-dhcp-server stop &>/dev/null
      cat > /etc/dhcp/dhcpd.conf << EOF
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
log-facility local7;
subnet $1 netmask $2 {
  authoritative;
  range $3 $4;
  option subnet-mask $2;
  option broadcast-address $bcastIP;
  option domain-name-servers $5;
}
EOF
    else
      bashlib_abort "$(caller)" "must be launched as root"
    fi
  else
    bashlib_abort "$(caller)" "[signature ip] [netmask] [starting range] [ending range] [static ip of the provider]"
  fi
}

# This function uses a given wifi interface to generate a wifi hotspot that anyone can connect to. This can be used for example to share your internet
# connection from ethernet to other computers locally (see 'wifi_shareInternet')
# arg0: The wifi interface to use
# arg1: The name of the network you want to create
# arg2: The password to connect to the hotspot (empty if you don't want any)
# arg3: The ip of the hotspot (expects to have a 24 bits netmask)
# Example:
#   # wifi_setupDHCP needs to be called here
#   wifi_createHotspot "wlan0" "MyHotspot" "1234" "192.168.5.1"
#   echo "Now anyone can connect to this nice new network !"
#   # wifi_shareInternet can be called here to share internet access to this network
# Please note that the DHCP server has to be setup properly according to the hotspot you want to create before calling this function. See 'wifi_setupDHCP'.
#@DEPENDS: network-manager, isc-dhcp-server
function wifi_createHotspot() {
  if [[ $# -eq 4 ]]; then
    if [[ $EUID -eq 0 ]]; then
      local interface=$1
      local SSID=$2
      local password=$3
      local hotspotIp=$4
      nmcli radio wifi on &>/dev/null
      ifconfig "$interface" up &>/dev/null
      if [[ "$password" == "" ]]; then
        nmcli con add con-name "hotspot" type wifi ifname "$interface" ssid "$SSID" -- 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared ipv4.method manual ipv4.address "$hotspotIp"/24 &>/dev/null
      else
        nmcli con add con-name "hotspot" type wifi ifname "$interface" ssid "$SSID" -- wifi-sec.key-mgmt wpa-psk 802-11-wireless.mode ap wifi-sec.psk "$password" 802-11-wireless.band bg ipv4.method shared ipv4.method manual ipv4.address "$hotspotIp"/24 &>/dev/null
      fi
      if nmcli con up "hotspot" &>/dev/null; then
        dhclient -r "$interface"
        pkill -f "dhclient $interface"
        service isc-dhcp-server stop &>/dev/null
        ifconfig "$interface" "$hotspotIp" netmask 255.255.255.0 &>/dev/null
        service isc-dhcp-server start &>/dev/null
      fi
    else
      bashlib_abort "$(caller)" "must be launched as root"
    fi
  else
    bashlib_abort "$(caller)" "[wifi interface] [hotspot name] [password (can be empty)] [ip]"
  fi
}


function wifi_startMonitorHotspot() {
  true
}

function wifi_stopMonitorHotspot() {
  true
}

# This function stops the hotspot launched by the wifi_createHotspot function, depending on the OS the system will automatically re-connect itself to the last
# valid connection if any is availabel
#@DEPENDS: network-manager
function wifi_stopHotspot() {
  wifi_stopMonitorHotspot
  nmcli con del "hotspot" &>/dev/null
}

#@DEPENDS iptables
function wifi_shareInternet() {
  true
}

