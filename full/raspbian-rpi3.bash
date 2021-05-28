#!/bin/bash
#https://www.pugetsystems.com/labs/hpc/Note-Auto-Install-Ubuntu-with-Custom-Preseed-ISO-1654/ iso's ^:/
programname=$0

if test "$#" -ne 1; then
    echo "usage: $programname unix.img.xz"
    exit
fi

compression=`file $1 | awk '{print $2}'`


echo Compression detected: $compression


if [ -d ~/mnt ]; then
    echo Old mnt Removed
    sudo umount ~/mnt
    sudo rm -rf ~/mnt

fi

if [ -f ~/ansible.img ]; then
    echo Old ansible.img Removed
    sudo rm -rf ~/ansible.img
fi

echo Check RSA Publickey
if [ -f ".ssh/id_rsa.pub" ]; then
    echo RSA Found;
else
    echo please run ssh-keygen
    exit
    # echo Generate RSA;
    # ssh-keygen -q -N "";
fi

if [[ $compression == XZ ]]; then
    echo Create Duplicate
    cp $1 ~/ansible.img.xz

    echo Decompress the Image
    xz --decompress ~/ansible.img.xz

fi   

if [[  $compression == XZ ]]; then
    echo Create Mountpoint
    mkdir ~/mnt

    startbit=`fdisk -l ~/ansible.img -o start,id,type | grep "83 Linux" | awk '{print $1}'`
    echo Start bit for root: $startbit
    sectorsize1=`fdisk -l ~/ansible.img | grep "I/O size" | awk '{print $4}'`
    echo Sector Size: $sectorsize1

    echo Mountbit: $(($startbit*$sectorsize1))

    #   526336  *    512
    # Start Bit * Sector Size

    echo Mount Image
    sudo mount -o loop,offset=$(($startbit*$sectorsize1)) ~/ansible.img ~/mnt

fi




#--------------------------------------------------------#
# Raspberry PI 3:
# 269484032 b3a80ce2979a0841c06831475993cfff80e5614c Ubuntu    ARM64 ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
#
#
#
#
#
# TODO: offset by sha hash
#--------------------------------------------------------#

if [ -d ~/mnt/etc/ ]; then
    echo "Mount Suxxxxxess"
else
    echo unmount mnt
    sudo umount ~/mnt

    echo Remove Mountpoint
    sudo rm -rf ~/mnt

    echo "Error: Mount failed.  Can't continue."
    exit 1
fi

echo Copy RSA to root fs
sudo cp ~/.ssh/id_rsa.pub ~/mnt/id_rsa.pub


echo Create notifyer.service
cat <<'EOF' >> ~/notifyer.service
[Unit]
Description=Multicast notifyer

[Service]
ExecStart=/notifyer

[Install]
WantedBy=multi-user.target
EOF

echo Copy notifyer.service to Root fs
sudo cp -f ~/notifyer.service ~/mnt/etc/systemd/system/notifyer.service

echo Remove notifyer.service
rm  ~/notifyer.service



echo Create netconfig
cat <<'EOF' >> ~/netconfig
#!/bin/bash

if [ -d /v6UdpMcastClt ]; then
  pacman-key --init
  pacman-key --populate archlinuxarm
  pacman -Syu

    sudo rm -rf /v6UdpMcastClt.c

fi

interface=`ip -o -6 route show to default | awk '{print $5}'`
echo hostname: `hostname` gateway: `ip -o -6 route show to default | awk '{print $3}'` global6: `ip addr show $interface | grep global | grep inet6 | awk '{print $2}'` link-local: `ip addr show $interface | grep link | grep inet6 | awk '{print $2}'` mac_addr: `ip addr show $interface | grep ether  | awk '{print $2}'` status: `systemctl status | grep "  State: " | awk '{print $2}'` failed: `systemctl status | grep "  Failed: " | awk '{print $2}'` units
EOF

echo Copy netconfig to Root fs
sudo cp -f ~/netconfig ~/mnt/

echo Remove netconfig
rm  ~/netconfig

echo Create modification.txt
cat <<'EOF' >> ~/modification.txt
Add User: ansible (pw: ansible)
Added Directory: /home/ansible/.ssh
Added File: /netconfig
Added File: /notifyer
Added File: /v6UdpMcastClt
Added File: /home/ansible/modification.txt
Added File: /home/ansible/.ssh/authorized_keys
Set Hostname: "pending-setup" > /etc/hostname
Systemd Service Enabled: /etc/systemd/system/notifyer.service
EOF

echo Copy modification.txt to Root fs
sudo cp -f ~/modification.txt ~/mnt/modification.txt

echo Remove modification.txt
rm  ~/modification.txt



rm ~/v6UdpMcastClt.c
rm ~/v6UdpMcastSrv.c

cat <<'EOF' >> ~/v6UdpMcastClt.c
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>

int
main(int argc, char *argv[])
{
	struct sockaddr_in6 saddr;
	struct ipv6_mreq mreq;
	char buf[1400];
	ssize_t len = 1;
	int sd, fd, on = 1, hops = 255, ifidx = 0;

	if (argc < 3) {
		printf("\nUsage: %s <address> <port>\n\nExample: %s ff02::5:6 12345\n\n", argv[0], argv[0]);
		return 1;
	}

	sd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);
	if (sd < 0) {
		return 1;
	}

	if (setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on))) {
		return 1;
	}

	if (setsockopt(sd, IPPROTO_IPV6, IPV6_MULTICAST_IF, &ifidx, sizeof(ifidx))) {
		return 1;
	}

	if (setsockopt(sd, IPPROTO_IPV6, IPV6_MULTICAST_HOPS, &hops, sizeof(hops))) {
		return 1;
	}

	if (setsockopt(sd, IPPROTO_IPV6, IPV6_MULTICAST_LOOP, &on, sizeof(on))) {
		return 1;
	}

	memset(&saddr, 0, sizeof(struct sockaddr_in6));
	saddr.sin6_family = AF_INET6;
	saddr.sin6_port = htons(atoi(argv[2]));
	inet_pton(AF_INET6, argv[1], &saddr.sin6_addr);

	memcpy(&mreq.ipv6mr_multiaddr, &saddr.sin6_addr, sizeof(mreq.ipv6mr_multiaddr));
	mreq.ipv6mr_interface = ifidx;

	if (setsockopt(sd, IPPROTO_IPV6, IPV6_JOIN_GROUP, (char *) &mreq, sizeof(mreq))) {
		return 1;
	}

	fd = open("/dev/stdin", O_RDONLY, NULL);
	if (fd < 0) {
		return 1;
	}

	while (len) {
		len = read(fd, buf, 1400);
		if (!len) {
			break;
		} else if (len < 0) {
			return 1;
		} else {
			len = sendto(sd, buf, len, 0, (const struct sockaddr *) &saddr, sizeof(saddr));

			usleep(10000);
		}
	}
	close(sd);
	close(fd);
	return 0;
}
EOF

echo Copy modification.txt to Root fs
sudo cp -f ~/v6UdpMcastClt.c ~/mnt/v6UdpMcastClt.c

cat <<'EOF' >> ~/v6UdpMcastSrv.c
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char *argv[])
{
        struct sockaddr_in6 saddr, maddr;
        struct ipv6_mreq mreq;
        char buf[1400];
        ssize_t len;
        int sd, fd, on = 1, flag = 0, hops = 255, ifidx = 0;
        fd_set fds;

        if (argc < 3) {
                printf("\nUsage: %s <address> <port>\n\nExample: %s ff02::9999 9999\n\n", argv[0], argv[0]);
                return 1;
        }

        sd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_UDP);
        if (sd < 0) {
                return 1;
        }

        if (setsockopt(sd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on))) {
                return 1;
        }

        if (setsockopt(sd, IPPROTO_IPV6, IPV6_MULTICAST_IF, &ifidx, sizeof(ifidx))) {
                return 1;
        }

        if (setsockopt(sd, IPPROTO_IPV6, IPV6_MULTICAST_HOPS, &hops, sizeof(hops))) {
                return 1;
        }

        if (setsockopt(sd, IPPROTO_IPV6, IPV6_MULTICAST_LOOP, &on, sizeof(on))) {
                return 1;
        }

        memset(&saddr, 0, sizeof(saddr));
        saddr.sin6_family = AF_INET6;
        saddr.sin6_port = htons(atoi(argv[2]));
        saddr.sin6_addr = in6addr_any;

        if (bind(sd, (struct sockaddr *) &saddr, sizeof(saddr))) {
                return 1;
        }

        memset(&maddr, 0, sizeof(maddr));
        inet_pton(AF_INET6, argv[1], &maddr.sin6_addr);

        memcpy(&mreq.ipv6mr_multiaddr, &maddr.sin6_addr, sizeof(mreq.ipv6mr_multiaddr));
        mreq.ipv6mr_interface = ifidx;

        if (setsockopt(sd, IPPROTO_IPV6, IPV6_JOIN_GROUP, (char *) &mreq, sizeof(mreq))) {
                return 1;
        }
        FD_ZERO(&fds);
        FD_SET(sd, &fds);
        fd = open("/dev/stdout", O_WRONLY, NULL);
        if (fd < 0) {
                return 1;
        }

        while (1) {
                len = read(sd, buf, 1400);
                buf[len] = '\0';

                if (!len) {
                        break;
                } else if (len < 0) {
                        return 1;
                } else {
                        len = write(fd, buf, len);
                        flag++;
                }
        }
        close(sd);
        close(fd);
        return 0;
}
EOF
echo Build Mcast Server
gcc -Wall -g ~/v6UdpMcastSrv.c -o ~/v6UdpMcastSrv
echo Build Mcast Client
gcc -Wall -g ~/v6UdpMcastClt.c -o ~/v6UdpMcastClt
echo copy mcast Client
sudo cp ~/v6UdpMcastClt ~/mnt/v6UdpMcastClt

if [[ $compression == XZ ]]; then
    echo Chroot
    #perl -e 'print crypt("ansible", "salt"),"\n"'
    sudo chroot ~/mnt/ /bin/bash << "EOT"
useradd -m -s $(which bash) -p sa/o2qVjeFay2 -G sudo ansible
gpasswd -d ubuntu sudo
mkdir -p /home/ansible/.ssh
cat /id_rsa.pub > /home/ansible/.ssh/authorized_keys
mv /modification.txt /home/ansible/modification.txt
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/
rm /id_rsa.pub
echo "pending-setup" > /etc/hostname
echo "#!/bin/bash" > /notifyer
echo "while true; do sleep 60; /netconfig | /v6UdpMcastClt ff03::22 9999 ; done" >> /notifyer
chmod +x /notifyer
chmod +x /netconfig
chmod +x /v6UdpMcastClt
systemctl enable notifyer.service
EOT
fi



echo Unmount Image
sudo umount ~/mnt

echo Remove Mountpoint
sudo rm -rf ~/mnt

echo -e "\e[32mFinished, $1-ansible.img created\e[0m"

mv ansible.img $1-ansible.img

echo Run Mcast Server: ./v6UdpMcastSrv ff03::22 9999





