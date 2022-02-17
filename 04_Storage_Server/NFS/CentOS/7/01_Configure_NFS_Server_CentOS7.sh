"Configure NFS Server to share directories on your Network."
# This example is based on the environment below.

+---------------------------+    |    +------------------------+
| NFS Server                |    |    | NFS Client             |
| masternode1.itstorage.net +----+----+ client1..itstorage.net |
| 192.168.37.30             |         | 192.168.37.40          |
+---------------------------+         +------------------------+

#1 Configure NFS Server.
#1.1 Run NFS Server on Master Node
[root@masternode1:~]# yum -y install nfs-utils
[root@masternode1:~]# vi /etc/idmapd.conf
# line 5: uncomment and change to your domain name
Domain = itstorage.net

#1.2 enable services and write settings for NFS exports
[root@masternode1:~]# vi /etc/exports
/home/nfsshare 192.168.37.0/24(rw,no_root_squash)
[root@masternode1:~]# mkdir /home/nfsshare
[root@masternode1:~]# systemctl start rpcbind nfs-server
[root@masternode1:~]# systemctl enable rpcbind nfs-server
[root@masternode1:~]# chmod -R 755 /home/nfsshare
[root@masternode1:~]# chown nfsnobody:nfsnobody /home/nfsshare
[root@masternode1:~]# systemctl enable rpcbind
[root@masternode1:~]# systemctl enable nfs-server
[root@masternode1:~]# systemctl enable nfs-lock
[root@masternode1:~]# systemctl enable nfs-idmap
[root@masternode1:~]# systemctl start rpcbind
[root@masternode1:~]# systemctl start nfs-server
[root@masternode1:~]# systemctl start nfs-lock
[root@masternode1:~]# systemctl start nfs-idmap
#-----------------------------------------------------------------------
#2 If Firewalld is running, allow NFS service.
#2.1 allow NFSv4
[root@masternode1:~]# firewall-cmd --add-service=nfs --permanent
success
#2.2 if allow NFSv3 too, set follows
[root@masternode1:~]# firewall-cmd --add-service={nfs3,mountd,rpc-bind} --permanent
success
[root@masternode1:~]# firewall-cmd --reload
success
#-----------------------------------------------------------------------
#3 Configure NFS client
# In my case, I have a CentOS 7 desktop as client. Other CentOS versions will also work the same way. Install the nfs-utild package as follows:
[root@client1:~]# yum install -y nfs-utils
# mount nfs from a client
[root@client1:~]# mount -t nfs 192.168.37.30:/home/nfsshare /mnt/
#-----------------------------------------------------------------------
#For basic options of exports
#Option	        Description
#------         -----------
rw	            #Allow both read and write requests on a NFS volume.
ro	            #Allow only read requests on a NFS volume.
sync	        #Reply to requests only after the changes have been committed to stable storage. (Default)

async	        #This option allows the NFS server to violate the NFS protocol and reply to requests before any changes made by that request have been committed to stable storage.

secure	        #This option requires that requests originate on an Internet port less than IPPORT_RESERVED (1024). (Default)

insecure	    #This option accepts all ports.
wdelay	        #Delay committing a write request to disc slightly if it suspects that another related write request may be in progress or may arrive soon. (Default)

no_wdelay	    #This option has no effect if async is also set. The NFS server will normally delay committing a write request to disc slightly if it suspects that another related write request may be in progress or may arrive soon. This allows multiple write requests to be committed to disc with the one operation which can improve performance. If an NFS server received mainly small unrelated requests, this behaviour could actually reduce performance, so no_wdelay is available to turn it off.

subtree_check   #This option enables subtree checking. (Default)
no_subtree_check #This option disables subtree checking, which has mild security implications, but can improve reliability in some circumstances.

root_squash	    #Map requests from uid/gid 0 to the anonymous uid/gid. Note that this does not apply to any other uids or gids that might be equally sensitive, such as user bin or group staff.

no_root_squash	#Turn off root squashing. This option is mainly useful for disk-less clients.

all_squash	    #Map all uids and gids to the anonymous user. Useful for NFS exported public FTP directories, news spool directories, etc.

no_all_squash	#Turn off all squashing. (Default)

anonuid=UID	    #These options explicitly set the uid and gid of the anonymous account. This option is primarily useful for PC/NFS clients, where you might want all requests appear to be from one user. As an example, consider the export entry for /home/joe in the example section below, which maps all requests to uid 150.

anongid=GID	    #Read above (anonuid=UID)

