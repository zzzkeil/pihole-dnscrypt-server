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
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Install dnscrypt                                                           ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} ${GREEN}Infos @ https://github.com/zzzkeil/pihole-dnscrypt-server                  ${ENDCOLOR}${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR}                 Version 2023.10.XX - changelog on github                   ${GRAYB}#${ENDCOLOR}"
echo -e " ${GRAYB}##############################################################################${ENDCOLOR}"
echo -e " ${GRAYB}#${ENDCOLOR} You need to run this as root  with     sudo -i                              ${GRAYB}#${ENDCOLOR}"
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
# Architecture check for dnsscrpt
#
ARCH=$(uname -m)
if [[ "$ARCH" == x86_64* ]]; then
  dnsscrpt_arch=x86_64
elif [[ "$ARCH" == aarch64* ]]; then
    dnsscrpt_arch=arm64
else
   echo -e "${RED}This script is only for x86_64 or ARM64  Architecture !${ENDCOLOR}"
   exit 1
fi
echo -e "${GREEN}Arch = $dnsscrpt_arch ${ENDCOLOR}"


###setup DNSCrypt
mkdir /etc/dnscrypt-proxy/
wget -O /etc/dnscrypt-proxy/dnscrypt-proxy.tar.gz https://github.com/DNSCrypt/dnscrypt-proxy/releases/download/2.1.5/dnscrypt-proxy-linux_$dnsscrpt_arch-2.1.5.tar.gz
tar -xvzf /etc/dnscrypt-proxy/dnscrypt-proxy.tar.gz -C /etc/dnscrypt-proxy/
mv -f /etc/dnscrypt-proxy/linux-$dnsscrpt_arch/* /etc/dnscrypt-proxy/
curl -o /etc/dnscrypt-proxy/dnscrypt-proxy.toml https://raw.githubusercontent.com/zzzkeil/pihole-dnscrypt-server/main/tools/dnscrypt-proxy.toml
curl -o /etc/dnscrypt-proxy/dnscrypt-proxy-update.sh https://raw.githubusercontent.com/zzzkeil/Wireguard-DNScrypt-VPN-Server/master/tools/dnscrypt-proxy-update.sh
chmod +x /etc/dnscrypt-proxy/dnscrypt-proxy-update.sh


#(crontab -l ; echo "59 23 * * 6 /etc/dnscrypt-proxy/dnscrypt-proxy-update.sh") | sort - | uniq - | crontab -

/etc/dnscrypt-proxy/dnscrypt-proxy -service install
/etc/dnscrypt-proxy/dnscrypt-proxy -service start

echo '#!/bin/sh
runtime1=$(uptime -s)
runtime2=$(uptime -p)
echo "System uptime : $runtime1  / $runtime2 "
echo ""
' >> /etc/update-motd.d/99-base01
chmod +x /etc/update-motd.d/99-base01

exit
