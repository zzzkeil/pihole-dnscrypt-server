#!/bin/bash

# visual text settings
RED="\e[31m"
GREEN="\e[32m"
GRAY="\e[37m"
YELLOW="\e[93m"

REDB="\e[41m"
GREENB="\e[42m"
GRAYB="\e[47m"
ENDCOLOR="\e[0m"

clear
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Base server config 4 debian / raspberry pi lite                            ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}This script installs an configure :                                        ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}password,ssh,ufw,network,unattended-upgrades                               ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Infos @ https://github.com/zzzkeil/pihole-dnscrypt-server                  ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR}                 Version 2023.10.XX - changelog on github                   ${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo ""
echo ""

echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${RED}! Warning, this script activate root user                                   ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} You need to run this as root  with     sudo -i                             ${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${REDB}#${ENDCOLOR} under construction :) dont run this script now                             ${REDB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"

echo ""
echo  -e "                    ${RED}To EXIT this script press any key${ENDCOLOR}"
echo ""
echo  -e "                            ${GREEN}Press [Y] to begin${ENDCOLOR}"
read -p "" -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

#
#root check
#

if [[ "$EUID" -ne 0 ]]; then
	echo -e "${RED}Sorry, you need to run this as root with  sudo -i  ${ENDCOLOR}"
	exit 1
fi


#
# check if Debian 
#

echo -e "${GREEN}OS check ${ENDCOLOR}"
. /etc/os-release
if [[ "$ID" = 'debian' ]]; then
   echo -e "OS ID check = ${GREEN}ok${ENDCOLOR}"
   else 
   echo -e "${RED}This script is only for Debian ${ENDCOLOR}"
   exit 1
fi

#
# APT
#

echo -e "${GREEN}apt update upgrade and install ${ENDCOLOR}"
apt update && apt upgrade -y && apt autoremove -y
apt install ufw unattended-upgrades apt-listchanges -y 
mkdir /root/script_backupfiles/
clear

#
# Password
#
echo -e " ${GREEN}Set a secure root password ${ENDCOLOR}"

echo ""
echo " This script can create a random secure root password."
echo " You may want to use PubkeyAuthentication, so setup this later by yourself"
echo ""
echo ""
echo  -e " ${GRAY}Press any key  -  to ${RED}NOT${ENDCOLOR} change root password ${ENDCOLOR}"
echo ""
echo  -e " ${GRAY}Press [C]  -  to create a secure random root password for local servers ${ENDCOLOR}"
read -p "" -n 1 -r
echo ""
echo ""
if [[ ! $REPLY =~ ^[Cc]$ ]]
then
newpass=0
echo " Ok no password change"
echo " Get sure you use a secure password or use PubkeyAuthentication !"
echo ""
echo ""
read -p "Press enter to continue"
else
newpass=1
randompasswd=$(</dev/urandom tr -dc 'A-Za-z0-9!"?%&' | head -c 16  ; echo)
echo "root:$randompasswd" | chpasswd
echo ""
echo ""
echo " Your new root password is : "
echo ""
echo -e "${GREEN}$randompasswd${ENDCOLOR}  <<< copy your new green password "
echo ""
echo -e "${YELLOW} !!! Save this password now !!! ${ENDCOLOR}"
echo " Use your mouse to mark the green password (copy), and paste it on your secure location (other computer/passwordmanager/...) !"
echo ""
echo " if you not save this password, you can never loggin again, be carefull"
echo ""
echo ""
read -p "Press enter to continue"
echo ""
echo " just one more time. "
echo " if you not save this password, you can never loggin again, be carefull"
echo ""
echo ""
read -p "Press enter to continue"
fi

clear

#
# SSH
#

echo -e "${GREEN}Set ssh config  ${ENDCOLOR}"
read -p "Choose your SSH Port: (default 22) " -e -i 2299 sshport
ssh-keygen -f /etc/ssh/key1ecdsa -t ecdsa -b 521 -N ""
ssh-keygen -f /etc/ssh/key2ed25519 -t ed25519 -N ""

mv /etc/ssh/sshd_config /root/script_backupfiles/sshd_config.orig
echo "Port $sshport
HostKey /etc/ssh/key1ecdsa
HostKey /etc/ssh/key2ed25519
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519  
KexAlgorithms curve25519-sha256                                 
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com    
MACs hmac-sha2-512-etm@openssh.com
HostbasedAcceptedKeyTypes ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,ssh-ed25519

PermitRootLogin yes
PasswordAuthentication yes
#PubkeyAuthentication yes

MaxAuthTries 2
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitEmptyPasswords no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp  internal-sftp 
UseDNS no
Compression no
LoginGraceTime 45
ClientAliveCountMax 1
ClientAliveInterval 1800
IgnoreRhosts yes">> /etc/ssh/sshd_config
clear

#
# Network
#

echo -e "${GREEN}Set network config  ${ENDCOLOR}"
read -p "Your hostname :" -e -i remotehost hostnamex
hostnamectl set-hostname $hostnamex

#clear

#
# UFW
#

echo -e "${GREEN}Set ufw config  ${ENDCOLOR}"
read -p "Allow ssh from Private IP Address or Range - CIDR : " -e -i 192.168.0.0/16 cidr
ufw default deny incoming
ufw allow from $cidr proto tcp to any port $sshport
#ufw allow from 192.168.0.0/16 to any port $sshport/tcp
#ufw allow from 172.16.0.0/12 to any port $sshport/tcp
#ufw allow from 10.0.0.0/8 to any port $sshport/tcp
#clear


#
# Updates
#

echo -e "${GREEN}unattended-upgrades  ${ENDCOLOR}"
mv /etc/apt/apt.conf.d/50unattended-upgrades /root/script_backupfiles/50unattended-upgrades.orig
echo 'Unattended-Upgrade::Allowed-Origins {
        "${distro_id}:${distro_codename}";
	"${distro_id}:${distro_codename}-security";
	"${distro_id}ESM:${distro_codename}";
//	"${distro_id}:${distro_codename}-updates";
//	"${distro_id}:${distro_codename}-proposed";
//	"${distro_id}:${distro_codename}-backports";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "01:30";
' >> /etc/apt/apt.conf.d/50unattended-upgrades

echo '
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
' >> /etc/apt/apt.conf.d/20auto-upgrades


nano /etc/apt/apt.conf.d/50unattended-upgrades
nano /etc/apt/apt.conf.d/20auto-upgrades

sed -i "s@6,18:00@9,23:00@" /lib/systemd/system/apt-daily.timer
sed -i "s@12h@1h@" /lib/systemd/system/apt-daily.timer
sed -i "s@6:00@1:00@" /lib/systemd/system/apt-daily-upgrade.timer
#clear

#
# download pihole dnscrypt sh
#
wget -O pihole_basic-install.sh https://install.pi-hole.net
chmod +x pihole_basic-install.sh


wget -O  dnscrypt_setup.sh https://raw.githubusercontent.com/zzzkeil/pihole-dnscrypt-server/main/dnscrypt_setup.sh
chmod +x dnscrypt_setup.sh


#
#misc
#

echo -e "${GREEN}Clear/Change some stuff ${ENDCOLOR}"

echo '#!/bin/sh
runtime1=$(uptime -s)
runtime2=$(uptime -p)
echo "System uptime : $runtime1  / $runtime2 "
echo ""
echo "Now run ./pihole_basic-install.sh and after ./dnscrypt_setup.sh to finish the setup"
' >> /etc/update-motd.d/99-base01
chmod +x /etc/update-motd.d/99-base01

echo "base_server script installed from :
https://github.com/zzzkeil/pihole-dnscrypt-server
" > /root/base_setup.README


#
# END
#

#clear
echo ""
echo ""
if [[ "$newpass" -ne 0 ]]; then
echo -e " ${YELLOW}!!! REMEMBER - you set a new root password :"
echo  ""
echo -e "${GREEN}$randompasswd${ENDCOLOR}  <<< copy your new green password "
echo ""
echo -e " ${RED}if you not save this password, you can never loggin again, be carefull ${ENDCOLOR}"
echo ""
echo ""
else
echo -e " ${YELLOW}!!! REMEMBER - you set a new root password :"
echo  ""
echo -e "${GREEN}$yourpasswd${ENDCOLOR}  <<< copy your new green password "
echo ""
echo -e " ${RED}if you not save this password, you can never loggin again, be carefull ${ENDCOLOR}"
echo ""
echo ""
fi
echo ""
echo -e "${REDB}After reboot run ./pihole_basic-install.sh to finish the setup ${ENDCOLOR}"
echo ""
echo -e "${GREEN}Press enter to reboot  ${ENDCOLOR}"
read -p ""
ufw --force enable
ufw reload
reboot
