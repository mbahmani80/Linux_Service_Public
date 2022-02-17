#!/bin/bash

#=======================================================================
#0. Initial-Settings
#=======================================================================
##0.1-Install Server Minimal
#-----------------------------------------------------------------------
##0.2-Add Repositories 
#-----------------------------------------------------------------------
###0.2.1 Install a plugin to add priorities to each installed repositories.
yum -y install yum-plugin-priorities
###0.2.1.1 set [priority=1] to official repository
sed -i -e "s/\]$/\]\npriority=1/g" /etc/yum.repos.d/CentOS-Base.repo
#-----------------------------------------------------------------------
###0.2.2 Add EPEL Repository which is provided from Fedora project.
yum -y install epel-release
###0.2.2.1 set [priority=5]
sed -i -e "s/\]$/\]\npriority=5/g" /etc/yum.repos.d/epel.repo
###0.2.2.2 for another way, change to [enabled=0] and use it only when needed
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/epel.repo
###0.2.2.2 if [enabled=0], input a command to use the repository
yum --enablerepo=epel install [Package]
#-----------------------------------------------------------------------
###0.2.3 Add CentOS SCLo Software collections Repository.
yum -y install centos-release-scl-rh centos-release-scl
####0.2.3.1 set [priority=10]
sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
####0.2.3.2 for another way, change to [enabled=0] and use it only when needed
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
####0.2.3.2 if [enabled=0], input a command to use the repository
yum --enablerepo=centos-sclo-rh install [Package]
yum --enablerepo=centos-sclo-sclo install [Package]
#-----------------------------------------------------------------------
###0.2.4 Add Remi's RPM Repository which provides many useful packages.
yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
####0.2.4.1 set [priority=10]
sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/remi-safe.repo
####0.2.4.2 for another way, change to [enabled=0] and use it only when needed
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/remi-safe.repo
####0.2.4.2 if [enabled=0], input a command to use the repository
yum --enablerepo=remi-safe install [Package]
#-----------------------------------------------------------------------

#=======================================================================
#1. Install some useful packages
#=======================================================================
yum install mlocate vim sudo rsync testdisk \
htop iptraf-ng lshw python-pip python3-pip \
vconfig bridge-utils sipcalc nmon testdisk minicom \
sshfs htop nmon iotop sysstat  dstat tcpdump \
screen bzip2 mc gpm open-vm-tools  \
bash-completion bash-completion-extras openssh-server tree

########################################################################
#2.setup Admin user (Just admin user can switch to root)
#=======================================================================
###2.1 Create an admin User
useradd sysadmin
passwd sysadmin
###2.2 Make sysadmin user who can switch to root as an admin user.
usermod -aG wheel,systemd-journal,tty sysadmin
[root@centos7 ~]# id sysadmin
uid=1001(sysadmin) gid=1001(sysadmin) groups=1001(sysadmin),5(tty),10(wheel),190(systemd-journal)
###2.3 vi /etc/pam.d/su
#%PAM-1.0
auth            sufficient      pam_rootok.so
# Uncomment the following line to implicitly trust users in the "wheel" group.
#auth           sufficient      pam_wheel.so trust use_uid
# Uncomment the following line to require a user to be in the "wheel" group.
# uncomment the following line
auth            required        pam_wheel.so use_uid
auth            substack        system-auth
auth            include         postlogin
account         sufficient      pam_succeed_if.so uid = 0 use_uid quiet
account         include         system-auth
password        include         system-auth
session         include         system-auth
session         include         postlogin
session         optional        pam_xauth.so

####To forward to emails for root user to another user, set like follows. (it's 'sysadmin' in this example)
vi /etc/aliases
# Person who should get root's mail
# last line: uncomment and change to a user
root: sysadmin
[root@centos7 ~]# newaliases

########################################################################
#3. Configure sudo
#=======================================================================
##3.1 Configure sudo to separate users' duty if some people share privileges.
visudo
## near line 115: add at the last line: user 'sysadmin' can use all root privilege
%wheel      ALL=(ALL)   NOPASSWD: ALL
sysadmin    ALL=(ALL)   NOPASSWD: ALL
#-----------------------------------------------------------------------
##3.2 Transfer some commands with root privilege to users in a group.
visudo
## near line 51: add aliase for the kind of user management comamnds
Cmnd_Alias USERMGR = /usr/sbin/useradd, /usr/sbin/userdel, /usr/sbin/usermod, /usr/bin/passwd, /bin/vi
## add at the last line
%usermgr ALL=(ALL) USERMGR
## run
groupadd usermgr
usermod -aG usermgr bahmani
#-----------------------------------------------------------------------
##3.3 In addition to the setting, set that some commands are not allowed.
visudo
## near line 50: add aliase for the kind of shutdown commands
Cmnd_Alias SHUTDOWN = /sbin/halt, /sbin/shutdown, /sbin/poweroff, /sbin/reboot, /sbin/init
## add ( commands in aliase 'SHUTDOWN' are not allowed )
%usermgr ALL=(ALL) USERMGR, !SHUTDOWN
## make sure with the user 'bahmani'
[root@centos7 ~]# su - bahmani
Last login: Sun Jan 16 03:34:05 +0330 2022 on pts/0
[bahmani@centos7 ~]$ sudo /sbin/shutdown -r now
[sudo] password for bahmani: 
Sorry, user bahmani is not allowed to execute '/sbin/shutdown -r now' as root on centos7.itstorage.ir.
[bahmani@centos7 ~]$ 

#-----------------------------------------------------------------------
##3.4 The logs for sudo are kept in '/var/log/secure', but there are many kind of logs in it. So if you'd like to keep only sudo's log in a file, Set like follows.
visudo
## add at the last line
Defaults syslog=local1
vi /etc/rsyslog.conf
## line 54: add
*.info;mail.none;authpriv.none;cron.none;local1.none   /var/log/messages
## add the line, too
local1.*                                                /var/log/sudo.log
## run
systemctl restart rsyslog
## test
[sysadmin@centos7:~]$ sudo ls

We trust you have received the usual lecture from the local System
Administrator. It usually boils down to these three things:

    #1) Respect the privacy of others.
    #2) Think before you type.
    #3) With great power comes great responsibility.

[sudo] password for sysadmin: 
[sysadmin@centos7:~]$ 

[root@centos7:~]# tail -f /var/log/sudo.log
Jan 15 19:17:44 centos7 sudo: sysadmin : TTY=pts/0 ; PWD=/home/sysadmin ; USER=root ; COMMAND=/bin/ls


########################################################################
#4. Network Settings
##4.1 Set static IP address to the server
nmcli dev

DEVICE  TYPE      STATE      CONNECTION 
ens33   ethernet  unmanaged  --         
lo      loopback  unmanaged  --         
#--------
chkconfig network off
systemctl enable NetworkManager
#--------
cat  /etc/NetworkManager/NetworkManager.conf 
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=true
#--------
nmcli dev

DEVICE  TYPE      STATE      CONNECTION 
ens33   ethernet  connected  ens33      
lo      loopback  unmanaged  --         
#--------
# Rename Connection if needed
nmcli con add type ethernet con-name ens33 ifname ens33
# set IPv4 address 
nmcli c modify ens33 ipv4.addresses 192.168.40.200/24
# set default gateway
nmcli c modify ens33 ipv4.gateway 192.168.40.1
# set DNS
nmcli c modify ens33 ipv4.dns "192.168.40.32 192.168.40.210" 
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

reboot
##4.2 Disable IPv6 if you don't need it.
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1">> /etc/sysctl.conf
# reload
sysctl -p
########################################################################
#5.Command Alias
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
#6. Configure vim
yum -y install vim-enhanced
# Set command alias. ( Apply to all users below. If you apply to a user, Write the same settings in '~/.bashrc' )
vi /etc/profile
# add at the last line
alias vi='vim'

source /etc/profile     # reload

#Configure vim. ( Apply to a user below. If you applly to all users, Write the same settings in '/etc/vimrc', some settings are applied by default though. )
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
set wrap

########################################################################
#7. rc.local
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
#8. Display Date And Time For Each Command
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

[root@centos7:~]# su - sysadmin
Last login: Sun Jan 16 03:42:02 +0330 2022 on pts/0
[sysadmin@centos7:~]$ 

[sysadmin@centos7:~]$ cat  ~/.bash_profile
#export PS1="\e[0;33;1m[\u@\h \W]\$ \e[m"
export PS1="[\[\e[32m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\]:\W]$ "
[sysadmin@centos7:~]$ source ~/.bash_profile

# root
[root@centos7:~]# cat  .bash_profile 
# Red / Green
export PS1="[\[\e[031m\]\u\[\e[m\]@\[\e[032m\]\h\[\e[m\]:\W]# "
[root@centos7:~]# source ~/.bash_profile

########################################################################
#10  Services
#=======================================================================
# display the list of services which are running
systemctl -t service
# the list of all services
systemctl list-unit-files -t service
# Stop and turn OFF auto-start setting for a service if you don'd need it. (it's smartd as an example below)
systemctl stop postfix
systemctl disable postfix
#There are some SysV services yet. Those are controled by chkconfig like follows.
[root@centos7 ~]# chkconfig --list

Note: This output shows SysV services only and does not include native
      systemd services. SysV configuration data might be overridden by native
      systemd configuration.

      If you want to list systemd services use 'systemctl list-unit-files'.
      To see services enabled on particular target use
      'systemctl list-dependencies [target]'.

netconsole     	0:off	1:off	2:off	3:off	4:off	5:off	6:off
network        	0:off	1:off	2:on	3:on	4:on	5:on	6:off
[root@centos7 ~]# 


# for exmaple, turn OFF auto-start setting for netconsole
chkconfig network off

########################################################################
#11. Disable firewalld and selinux
#=======================================================================
##11.1 It's possible to show Service Status of FireWall like follows. (enabled by default)
systemctl status firewalld
# If FireWall service does not need for you because of some reasons like that some FireWall Machines are running in your Local Netowrk or others, it's possbile to stop and disable it like follows.
# stop service
systemctl stop firewalld
# disable service
systemctl disable firewalld
#-----------------------------------------------------------------------
##11.2 It's possible to show Status of SELinux (Security-Enhanced Linux) like follows. (enabled by default)
getenforce
Enforcing     # SELinux is enabled
# If SELinux function does not need for you because of some reasons like that your server is running only in Local safety Network or others, it's possbile to disable it like follows.
vi /etc/selinux/config
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled   # change to disabled
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected.
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted

# restart to apply new setting
reboot
########################################################################
#12. Update your system with 'yum' command.
#=======================================================================
yum update -y
########################################################################
#13. journald
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
grep ^Storage /etc/systemd/journald.conf
Storage=auto
## Clear systemd journals if they exceed X storage
sudo journalctl --vacuum-size=500M
systemctl restart systemd-journald
########################################################################
#14. Reducing shutdown timeout for "a stop job is running"
vim /etc/systemd/systemd.conf
#or
vim /etc/systemd/system.conf

#Then uncomment the following lines :

#DefaultTimeoutStartSec=90s
#DefaultTimeoutStopSec=90s
#To :
DefaultTimeoutStartSec=10s
DefaultTimeoutStopSec=10s

#or
sed -i -r 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=30s/' /etc/systemd/system.conf
sed -i -r 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=30s/' /etc/systemd/system.conf

# then
systemctl daemon-reload
reboot
########################################################################
# 15
# 1.6 Changing Unique identifiers in Centos 7 after cloning a VM
https://manuelveronesi.freshdesk.com/support/solutions/articles/19000107613-changing-unique-identifiers-in-centos-7-after-cloning-a-vm

# Machine ID
# cat /etc/machine-id
daab00e07fed481d8ccf145b7affc0c5
# rm /etc/machine-id
# systemd-machine-id-setup
Initializing machine ID from random generator.
# cat /etc/machine-id
2175d9b2344a499abd87920c6f76f9a1

# Storage UUID
# Use blkid command-line utility to determine device UUID :
blkid

#Sample output :
/dev/mapper/centos_centos71-root: UUID="2bc8e0d4-64b5-4dc8-bf4a-024fc980d98a" TYPE="ext4"
/dev/mapper/centos_centos71-swap: UUID="577f9541-8d2a-4666-ac8f-ff84b584eeca" TYPE="swap"
/dev/mapper/vg_data-centos7_vol: UUID="b100ad2b-ad89-4e2d-ba8e-7eda7d703c40" TYPE="ext4"
Verify the mounted partition :
# df -lh
Filesystem                        Size  Used Avail Use% Mounted on
/dev/mapper/centos_centos71-root   24G  3.1G   19G  15% /
devtmpfs                          1.9G     0  1.9G   0% /dev
tmpfs                             1.9G     0  1.9G   0% /dev/shm
tmpfs                             1.9G   25M  1.9G   2% /run
tmpfs                             1.9G     0  1.9G   0% /sys/fs/cgroup
tmpfs                             500M     0  500M   0% /etc/nginx/cache
/dev/sda1                         477M  230M  218M  52% /boot
tmpfs                             380M     0  380M   0% /run/user/0
/dev/mapper/vg_data-centos7_vol   9.8G   37M  9.2G   1% /data
#How to change UUID for /dev/mapper/vg_data-centos7_vol which is in /data mounted partition 
# a) Generate new UUId using uuidgen utility :
uuidgen
fb5c697b-d1d6-49ab-afcd-27a22a5007c8
# b) Please take note that the UUID may only be changed when the filesystem is unmounted.
umount /data
#c) Change UUID for LVM /dev/mapper/vg_data-centos7_vol with new generated UUID :
tune2fs /dev/mapper/vg_data-centos7_vol -U fb5c697b-d1d6-49ab-afcd-27a22a5007c8
tune2fs 1.42.9 (28-Dec-2013)
# d) Mount back the /data partition :
mount /dev/mapper/vg_data-centos7_vol /data
#e) Update /etc/fstab :
# Option 1 :
UUID=fb5c697b-d1d6-49ab-afcd-27a22a5007c8 /data   ext4    defaults        1 2
# Option 2 :
/dev/mapper/vg_data-centos7_vol /data   ext4    defaults        1 2
# f) Verify new UUID for /dev/mapper/vg_data-centos7_vol
blkid
/dev/mapper/centos_centos71-root: UUID="2bc8e0d4-64b5-4dc8-bf4a-024fc980d98a" TYPE="ext4"
/dev/mapper/centos_centos71-swap: UUID="577f9541-8d2a-4666-ac8f-ff84b584eeca" TYPE="swap"
/dev/mapper/vg_data-centos7_vol: UUID="fb5c697b-d1d6-49ab-afcd-27a22a5007c8" TYPE="ext4"

# How to generate UUID for network interface
# UUIDs (Universal Unique Identifier) for network interface card can be generated using the following command :
uuidgen <DEVICE>
#Example :
uuidgen eth0
#Then you can add it to your NIC config file (assuming your interface is eth0) :
# NIC configuration fileShell
/etc/sysconfig/network-scripts/ifcfg-eth0
# Add/modify the following :
UUID=<uuid>
########################################################################


