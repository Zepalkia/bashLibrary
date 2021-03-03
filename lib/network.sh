#@DEPENDENCIES: network-manager, isc-dhcp-server, iptables, aircrack-ng, lsof
source string.sh

# This function performs a scan of the wifi to retrieve the available networks (only their SSID)
# arg0: The name of the variable that will contain the found SSIDs (array)
#@DEPENDS: network-manager
function network_scanWifi() {
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

# This function retrieves the mac address of the main (or given) interface
# arg0: The name of the interface (optional, if not given will be searched automatically)
# arg1: The name of the variable that will contain the mac address (string)
# Example:
#   network_macAddress address
#   echo "The mac address of the main wifi interface is: $address"
#@DEPENDS: network-manager
function network_macAddress() {
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

# This function sets the parameters of the DHCP server to make it ready to give IPs as expected by a hotspot for example (see network_createHotspot).
# arg0: The signature IP (e.g. 192.168.1.0)
# arg1: The netmask (e.g. 255.255.255.0)
# arg2: The starting IP range (e.g. 192.168.1.100)
# arg3: The ending IP range (e.g. 192.168.1.150)
# arg4: The static IP of the interface that will provide IP addresses (e.g. 192.168.5.1)
# Example:
#   sudo -s
#   network_setupDHCP 60.0.0.0 255.255.255.0 60.0.0.100 60.0.0.200 60.0.0.1
# Note:
#   Here by default the DHCP server will provide global google DNS, if you want to use another one you'll need to change this value
#@DEPENDS: isc-dhcp-server
function network_setupDHCP() {
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
  option routers $5;
  option domain-name-servers 8.8.8.8;
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
# connection from ethernet to other computers locally (see 'network_shareInternet')
# arg0: The wifi interface to use
# arg1: The name of the network you want to create
# arg2: The password to connect to the hotspot (empty if you don't want any)
# arg3: The ip of the hotspot (expects to have a 24 bits netmask)
# Example:
#   # network_setupDHCP needs to be called here
#   network_createHotspot "wlan0" "MyHotspot" "1234" "192.168.5.1"
#   echo "Now anyone can connect to this nice new network !"
#   # network_shareInternet can be called here to share internet access to this network
# Please note that the DHCP server has to be setup properly according to the hotspot you want to create before calling this function. See 'network_setupDHCP'.
#@DEPENDS: network-manager, isc-dhcp-server
function network_createHotspot() {
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


function network_startMonitorHotspot() {
  true
}

function network_stopMonitorHotspot() {
  true
}

# This function stops the hotspot launched by the network_createHotspot function, depending on the OS the system will automatically re-connect itself to the last
# valid connection if any is availabel
#@DEPENDS: network-manager
function network_stopHotspot() {
  network_stopMonitorHotspot
  nmcli con del "hotspot" &>/dev/null
}

# This function starts the connection sharing between 2 interfaces (e.g. wifi to ethernet), the first one needs to be connected to the internet
# arg0: The name of the interface sharing the connection (e.g. wlan0)
# arg1: The name of the interface that will transmit the connection (e.g. eth0)
# Note:
#  Any external computer plugged into the second interface (either WiFi hotspot or Ethernet connection) will be able to grab the connection given by the main
#  interface. Be aware than this computer could need to specify the route and/or grab an IP address depending on your situation, this sharing will only work if
#  all the other settings are fine as well
#@DEPENDS iptables
function network_shareInternet() {
  if [[ $# -eq 2 ]]; then
    sudo iptables -F
    sudo iptables -t nat -F
    echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward >/dev/null
    sudo iptables -A FORWARD -i "$2" -o "$1" -j ACCEPT
    sudo iptables -A FORWARD -i "$1" -o "$2" -m state --state RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -o "$1" -j MASQUERADE
  else
    bashlib_abort "$(caller)" "[connected interface] [sharing interface]"
  fi
}

# This function retrieves the name of the internal WiFi module of the computer
# arg0: The name of the variable that will contain the name of the module
function network_getWifiModule() {
  if [[ $# -eq 1 ]]; then
    local -n __WIFI_MODULE_NAME__=$1
    __WIFI_MODULE_NAME__=$(lspci -nnk | grep -iA2 "Wireless" | grep "Kernel modules" | awk '{print $3}')
  else
    bashlib_abort "$(caller)" "[&result]"
  fi
}

# This function disables completelly the WiFi module of the computer, either until next reboot or permanently
# arg0: A boolean telling if we want the change to be permanent (true) or not
# return: 0 if the module has been disabled successfully, 1 otherwise
# Note:
#  This function has to be run as root in order to be successful (see 'system_asRoot'), in case your computer is using iwlwifi module it will also require to
#  disable the 'iwlmvm' module before
function network_disableWifiModule() {
  if [[ $# -eq 1 ]]; then
    local __MODULE_DISABLED__=1
    local module=""
    network_getModule module
    if [[ "$module" != "" ]]; then
      if modprobe -r "$module" &>/dev/null; then
        if [[ "$1" == true ]]; then
          echo "blacklist $module" >> /etc/modprobe.d/blacklist-wifi.conf
        fi
        __MODULE_DISABLED__=0
      fi
    fi
  else
    bashlib_abort "$(caller)" "[disable permanently (boolean)]"
  fi
  return $__MODULE_DISABLED__
}

#@DEPENDS: lsof
function network_waitFileTransfer() {
  if [[ $# -eq 1 ]]; then
    until [[ $(lsof | grep -c "$1") -gt 0 ]]; do
      sleep 1
    done
  else
    bashlib_abort "$(caller)" "[path to file]"
  fi
}

#@DEPENDS: network-manager
function network_getCurrentIP() {
  if [[ $# -eq 2 ]]; then
    local -n __CURRENT_IP_ADDRESS__"$1"
    __CURRENT_IP_ADDRESS__=$(nmcli d show "$2" | grep "IP4.ADDRESS" | head -1 | awk -F '/' '{print $1}' | awk '{print $2}')
  else
    bashlib_abort "$(caller)" "[&result] [interface]"
  fi
}
