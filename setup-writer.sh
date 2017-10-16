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
127.0.1.1       LongRangeReader2
EOF
hostname LongRangeReader2
echo "[*][*] Writing to /etc/hostname"
echo "LongRangeReader2" > /etc/hostname;
###
#
#Update pi (hey, security right)
apt-get -y update && apt-get -y upgrade;
#
#Install reaquired packages
echo "[*] Installing Packages..."
apt-get update;
apt-get install -y git screen pigpio python-pip isc-dhcp-server hostapd build-essential python-dev p7zip git build-essential libreadline5 libreadline-dev libusb-0.1-4 libusb-dev libqt4-dev perl pkg-config wget libncurses5-dev gcc-arm-none-eabi libstdc++-arm-none-eabi-newlib sshfs;
pip install tornado pigpio;
###
#Copying project files
echo "[*] Installing LongRangeReader code to /opt/LongRangeReader/..."
mkdir -p /opt/LongRangeReader;
cp *.py /opt/LongRangeReader/
chmod +x /opt/LongRangeReader/*.py
###
###Create sshfs automount
echo sshfs#root@192.168.3.1:/opt/LongRangeReader /opt/LongRangeReader/mount fuse defaults,allow_other 0 0 >>/etc/fstab
#
###Setup Proxmark
git clone https://github.com/proxmark/proxmark3.git
mv proxmark3 /opt/
cd /opt/proxmark3/
cp -rf driver/77-mm-usb-device-blacklist.rules /etc/udev/rules.d/77-mm-usb-device-blacklist.rules
udevadm control --reload-rules
adduser $USER dialout
make clean && make all
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
        address 192.168.3.100
        netmask 255.255.255.0
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOM
###
#
### Setup wireless options
echo -n "Enter preferred SSID: "
read wifissid
echo -n "Enter WIFI PSK: "
read wifipsk
echo "[*][*] Writing wireless config"
cat > /etc/wpa_supplicant/wpa_supplicant.conf <<- EOM
country=AU
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
        ssid="$wifissid"
        psk="$wifipsk"
}

EOM
#
### Set DNS options
cat > /etc/resolv.conf <<- EOM
domain local
nameserver 8.8.8.8
nameserver 139.130.4.4
EOM
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
# Mount remote pi filesystem
mount -a
# Start long range reader script
screen -dmS lrr_webserver2 bash -c "cd /opt/LongRangeReader; su -c 'python ./lrr_webserver2.py'"
exit 0
EOM
###
#Reboot pi
echo "[*] Restarting Raspberry Pi in 10 seconds."
sleep 10;
reboot
###