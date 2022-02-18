#!/bin/bash
#0.Initial-Settings
##0.1 Add Repositories
##Debian Sources List Generator
###http://debgen.simplylinux.ch/
cat /etc/apt/sources.list

deb http://ftp.us.debian.org/debian/ buster main non-free contrib
deb-src http://ftp.us.debian.org/debian/ buster main non-free contrib
deb http://security.debian.org/debian-security buster/updates main contrib non-free
deb-src http://security.debian.org/debian-security buster/updates main contrib non-free
deb http://ftp.us.debian.org/debian/ buster-updates main contrib non-free
deb-src http://ftp.us.debian.org/debian/ buster-updates main contrib non-free


##0.1 Install Server Minimal
#Debian Install
apt-get update
apt-get dist-upgrade

##1-Initial-Settings
apt-get install locate vim sudo rsync testdisk fortune-mod  \
fortunes-debian-hints  fortunes dpkg-dev w3m htop vim module-assistant \
gcc linux-headers-$(uname -r) iptraf lshw python-ipcalc gnupg2 whiptail \
dialog vlan bridge-utils rar unrar ipcalc nmon iozone3 testdisk minicom \
sshfs autossh w3m htop nmon iotop  sysstat  dstat ipcalc tcpdump \
build-essential fakeroot screen libncurses5-dev bzip2 mc gpm vim-scripts \
vim-doc bash-completion make  openssh-server tree

apt install network-manager-openconnect network-manager-vpnc \
network-manager-pptp nethogs  dos2unix ntfs-3g mtools kpartx \
smbclient python-pip python3-pip snmp snmp-mibs-downloader dnsutils mtr

apt install open-vm-tools-dev grub2
apt install rkhunter
apt install zabbix-cli
########################################################################
#2.setup Admin user (Just admin user can switch to root)
###2.1 Create an admin User
useradd sysadmin
passwd sysadmin
###2.2 Make sysadmin user who can switch to root as an admin user.
usermod -aG adm sysadmin
usermod -aG sudo sysadmin
#https://wiki.debian.org/SystemGroups
usermod -aG adm,tty,cdrom,sudo,systemd-journal,netdev sysadmin
root@localhost:~# id sysadmin 
###line 15: uncomment and add the follows
grep adm  /etc/pam.d/su
auth       required   pam_wheel.so group=adm
####Other User can not switch to root 
sysadmin@Mahdi-MBCTUX ~ $ su -
Password: 
su - soroush
soroush@Mahdi-MBCTUX:~$ su -
Password: 
su: Permission denied
soroush@Mahdi-MBCTUX:~$ 
########################################################################
#3.Network Settings
##3.1 Set static IP address to the server
nmcli dev

DEVICE  TYPE      STATE      CONNECTION 
ens33   ethernet  unmanaged  --         
lo      loopback  unmanaged  --         
#--------
systemctl disable networking
systemctl enable NetworkManager
#--------
cat  /etc/NetworkManager/NetworkManager.conf 
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true
#--------
systemctl restart NetworkManager
#--------
nmcli dev

DEVICE  TYPE      STATE      CONNECTION 
ens33   ethernet  connected  ens33      
lo      loopback  unmanaged  --         
#--------
# Rename Connection if needed
nmcli con add type ethernet con-name ens33 ifname ens33
# set IPv4 address 
nmcli c modify ens33 ipv4.addresses 192.168.194.146/24
# set default gateway
nmcli c modify ens33 ipv4.gateway 192.168.194.2
# set DNS
nmcli c modify ens33 ipv4.dns "8.8.8.8 4.2.2.4" 
# Set manual for static setting (it's "auto" for DHCP)
nmcli c modify ens33 ipv4.method manual
# START ONBOOT
nmcli c modify ens33 connection.autoconnect yes
# Stop old networking service && Restart the interface and reload the settings
nmcli c down ens33; sudo nmcli c up ens33

# set hostname
hostnamectl set-hostname mysrv
nmcli general hostname mysrv

cat  /etc/hosts
127.0.0.1	localhost
192.168.194.146	mysrv.itstorage.ir	mysrv


##3.2 Disable IPv6 if you don't need it.
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1">> /etc/sysctl.conf
# reload
sysctl -p
########################################################################
#4.Command Alias
##Add these line to ~/.bash_profile for a single user 
##Add these line to /etc/profile for all user
##alias inserted by sysadmin
    alias ls='ls --color=always'
    alias ll='ls --color=always -l'
    alias la='ls --color=always -A'
    alias less='less -R'
    alias ls='ls --color=always'
    alias grep='grep --color=always'
    alias egrep='egrep --color=always'
    alias fgrep='fgrep --color=always'
    alias clear="clear; ls"
    alias home='cd ~'
    alias jobs='jobs -l'
    alias psx="ps -auxw ¦ grep "
    alias vi='vim'
    alias rm='rm -iv'
    alias cp='cp -riv'
    alias mkdir='mkdir -p'
    alias more='less'
    alias hclear='history -c; clear'
###fortune
#    /usr/games/fortune
####TimeZone & Editor & PS1
EDITOR=vim
export EDITOR
export TZ='Asia/Tehran'; export TZ
##Reload
source /etc/profile
source ~/.bash_profile
########################################################################
#5. Configure vim
mkdir ~/.backup
vi ~/.vimrc
set fileformats=unix,dos 
set backup 
set backupdir=~/.backup 
set history=50 
set ignorecase 
set smartcase 
set hlsearch 
set incsearch 
set number 
syntax on 
highlight Comment ctermfg=LightCyan 

########################################################################
#06. rc.local
cat <<EOF > rc-local.service
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF
mv rc-local.service /etc/systemd/system/
cat <<EOF > rc.local
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

exit 0
EOF
mv rc.local /etc/
chmod +x /etc/rc.local
systemctl daemon-reload
systemctl enable rc-local
systemctl start rc-local
systemctl status rc-local
########################################################################
#07. Display Date And Time For Each Command
echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> ~/.bashrc
echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> ~/.bash_profile
su - sysadmin
echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> ~/.bashrc
echo 'export HISTTIMEFORMAT="%d/%m/%y %T "' >> ~/.bash_profile
# Where,
# %d - Day
# %m - Month
# %y - Year
# %T - Time
########################################################################
# BASH Shell Change The Color of Shell Prompt on Linux or UNIX
cat  ~/.bash_profile
...

#export PS1="\e[0;33;1m[\u@\h \W]\$ \e[m"
export PS1="[\[\e[32m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\]:\W]$ "
[sysadmin@servicemon-zabbix:~]$ 

# Red / Green
export PS1="[\[\e[031m\]\u\[\e[m\]@\[\e[032m\]\h\[\e[m\]:\W]$ "


# or
cat  ~/.bash_profile
...

_GREEN=$(tput setaf 2)
_BLUE=$(tput setaf 4)
_RED=$(tput setaf 1)
_RESET=$(tput sgr0)
_BOLD=$(tput bold)
export PS1="${_GREEN}\h${_BLUE}@${_RED}\u${_RESET} ${_BOLD}\$ ${_RESET}"


# root
servicemon-zabbix@root # cat  .bash_profile 
export HISTTIMEFORMAT="%d/%m/%y %T "
_GREEN=$(tput setaf 2)
_BLUE=$(tput setaf 4)
_RED=$(tput setaf 1)
_RESET=$(tput sgr0)
_BOLD=$(tput bold)
export PS1="${_GREEN}\h${_BLUE}@${_RED}\u${_RESET} ${_BOLD}# ${_RESET}"
servicemon-zabbix@root #

mbctux@bahmani $ 
########################################################################
#08. Update your system with 'apt' command.
apt-get update
apt-get upgrade
apt-get dist-upgrade
