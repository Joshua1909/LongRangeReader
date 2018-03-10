#!/bin/bash
#
#Fix Raspbian SSH issues
#Credit https://expresshosting.net/ssh-hanging-authentication/
echo IPQoS 0x00 >>/etc/ssh/ssh_config
echo IPQoS 0x00 >>/etc/ssh/sshd_config
echo VerifyReverseMapping no >>/etc/ssh/sshd_config
echo UseDNS no >>/etc/ssh/sshd_config

service ssh restart
###
#
#Enable SSH
update-rc.d ssh enable
###
#
#Add host file entry for reader
echo "[*] Setting Hostname..."
echo "[*][*] Writing to /etc/hosts"
cat > /etc/hosts <<- EOF
127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
127.0.1.1       LongRangeReader
EOF
hostname LongRangeReader
echo "[*][*] Writing to /etc/hostname"
echo "LongRangeReader" > /etc/hostname;
###
#
#Update pi (hey, security right)
apt-get -y update && apt-get -y upgrade;
#
#Install reaquired packages
echo "[*] Installing Packages..."
apt-get update;
apt-get install -y git screen pigpio python-pip isc-dhcp-server hostapd build-essential python-dev dos2unix;
pip install tornado pigpio;
###
#
#Setup IP Addressing
echo "[*][*] Writing to /etc/network/interfaces"
cat > /etc/network/interfaces <<- EOM
auto lo
iface lo inet loopback
#
iface eth0 inet manual
#
allow-hotplug wlan0
iface wlan0 inet static
        post-up /usr/sbin/hostapd -B /etc/hostapd/hostapd.conf
        post-up service isc-dhcp-server restart
        address 192.168.3.1
        netmask 255.255.255.0
EOM
###
#
#Setup DHCP
echo "[*][*] Writing to /etc/dhcp/dhcpd.conf"
cat > /etc/dhcp/dhcpd.conf <<- EOM
ddns-update-style none;
default-lease-time 600;
max-lease-time 7200;
authoritative;
log-facility local7;

subnet 192.168.3.0 netmask 255.255.255.0 {
    range 192.168.3.2 192.168.3.50;
    option broadcast-address 192.168.3.255;
    option routers 192.168.3.1;
    default-lease-time 600;
    max-lease-time 7200;
    option domain-name "local";
    option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOM
#
echo "[*][*] Writing to /etc/default/isc-dhcp-server"
cat > /etc/default/isc-dhcp-server <<- EOM
INTERFACES="wlan0"
EOM
###
#
#Setup Hostapd
echo -n "Enter preferred WIFI PSK: "
read wifipsk
echo -n "Enter preferred SSID: "
read wifissid
echo "[*][*] Writing to /etc/hostapd/hostapd.conf"
cat > /etc/hostapd/hostapd.conf <<- EOM
interface=wlan0
driver=nl80211
ssid=$wifissid
hw_mode=g
channel=6
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$wifipsk
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOM
###
#
#Creating autostart
echo "[*] Writing boot files - /etc/rc.local"
cat > /etc/rc.local <<- EOM
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
#
# Print the IP address
_IP=\$(hostname -I) || true
if [ "\$_IP" ]; then
  printf "My IP address is %s\n" "\$_IP"
fi
#
# Start pigpio daemon
pigpiod
#
# Start long range reader script
screen -dmS lrr_wiegand_listener bash -c "cd /opt/LongRangeReader; su -c 'python ./lrr_wiegand_listener.py'"
#screen -dmS lrr_webserver bash -c "cd /opt/LongRangeReader; su -c 'python ./lrr_webserver.py'"
exit 0
EOM
###
#Copying project files
echo "[*] Installing LongRangeReader code to /opt/LongRangeReader/..."
mkdir -p /opt/LongRangeReader;
cp *.py /opt/LongRangeReader/
chmod +x /opt/LongRangeReader/*.py
dos2unix /opt/LongRangeReader/*.py
###
#Create cards CSV
touch /opt/LongRangeReader/cards.csv
###
#Auto start hostapd
echo "[*] Enabling hostapd on startup"
update-rc.d hostapd enable
###
#Reboot pi
echo "[*] Restarting Raspberry Pi in 10 seconds."
sleep 10;
reboot
###
