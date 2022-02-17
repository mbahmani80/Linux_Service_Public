# Configure NTP Client.
# 1	NTP Client configuration is mostly the same with the Server's one, though,
# NTP Clients do not need to receive time synchronization requests from other hosts, so it does not need to specify the line [allow ***].
dnf -y install chrony
vi /etc/chrony.conf
# line 3 : change to your own NTP server or others in your timezone
#pool 2.centos.pool.ntp.org iburst
pool ntpsrv.itstorage.net iburst
[root@node01 ~]# systemctl enable --now chronyd
# verify status
[root@node01 ~]# chronyc sources
