#!/bin/bash
#https://www.pugetsystems.com/labs/hpc/Note-Auto-Install-Ubuntu-with-Custom-Preseed-ISO-1654/ iso's ^:/
programname=$0

if test "$#" -ne 1; then
    echo "usage: $programname unix.img.xz"
    exit
fi

if [ -d ~/mnt ]; then
    echo Old mnt Removed
    sudo umount mnt
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


if [[ $1 == *.xz ]]; then
    echo Create Mountpoint
    mkdir ~/mnt

    echo Create Duplicate
    cp $1 ~/ansible.img.xz

    echo Decompress the Image
    xz --decompress ~/ansible.img.xz
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

if [[ $1 == *.raw.xz ]]; then
    echo Create Mountpoint
    mkdir ~/mnt

    echo Create Duplicate
    cp $1 ~/ansible.img.xz

    echo Decompress the Image
    xz --decompress ~/ansible.img.xz
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

if [[ $1 == *.zip ]]; then
    echo Create Mountpoint
    mkdir ~/mnt

    echo Unzip the Image
    unzip $1 -d ~/temp
    mv ~/temp/* ~/ansible.img
    rm -rf temp
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


if [[ $1 == *.tar.gz ]]; then

    echo Create Mountpoint
    mkdir ~/mnt

    echo Create ansible.img
    sudo dd of=~/ansible.img seek=3900M bs=1 count=0

    echo Create Patition Table
    sudo parted ~/ansible.img mktable msdos

    echo Create Boot  Patition
    sudo parted ~/ansible.img mkpart primary fat32 2048s 257MiB

    echo Create Root Patition
    sudo parted ~/ansible.img mkpart primary ext4 257MiB 100%

    echo Attach ansible.img to loop Device
    loop=`sudo losetup --find --partscan --show ansible.img`

    echo Create vfat on Boot Patition
    sudo mkfs.vfat -F 32 -n BOOT "${loop}p1"

    echo Create ext4 on Root Partition
    sudo mkfs.ext4 -L rootfs "${loop}p2"

    echo Mount Root Patition
    sudo mount "${loop}p2" ~/mnt/

    echo Mount Boot Patition
    sudo mkdir ~/mnt/boot
    sudo mount "${loop}p1" ~/mnt/boot

    echo UnTAR.gz the Image
    sudo bsdtar -xpf ~/$1 -C ~/mnt

    sync
fi


#--------------------------------------------------------#
# Raspberry PI 3:
# 269484032 b3a80ce2979a0841c06831475993cfff80e5614c Ubuntu    ARM64 ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
#   4194304 164e1bdd70d743eda3395444a5a5bbdedbab5b04 Debian    ARMHF bone-debian-10.3-iot-armhf-2020-04-06-4gb.img.xz
#   4194304 8be911fb79156cf4f80bc1451f887883359bca46 Debian    ARMHF bone-eMMC-flasher-debian-10.3-iot-armhf-2020-04-06-4gb.img.xz
#    532480 f30f9bb907a33736b7d7543da80fac3b1d6c6651 Debian    ARMHF 2021-03-04-raspios-buster-armhf-lite.zip
#         0 4f0fe7bc9944ca244c3f719da46386200d94a253 ArchLinux ARM64 ArchLinuxARM-rpi-2-latest.tar.gz
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

    echo "Error: Mount failed.  Can not continue."
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

if [[ $1 == *.xz ]]; then

    echo Chroot
    #perl -e 'print crypt("ansible", "salt"),"\n"'
    sudo chroot ~/mnt/ /bin/bash << "EOT"
useradd -m -s $(which bash) -p sa/o2qVjeFay2 -G sudo ansible
gpasswd -d ubuntu sudo
mkdir -p /home/ansible/.ssh
cat /id_rsa.pub > /home/ansible/.ssh/authorized_keys
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/
rm /id_rsa.pub
echo "pending-setup" > /etc/hostname
echo "#!/bin/bash" > /notifyer
echo "while true; do     sleep 60;     echo \`ip addr\` | /v6UdpMcastClt ff03::22 9999 ; done" >> /notifyer
chmod +x /notifyer
chmod +x /v6UdpMcastClt
systemctl enable notifyer.service
EOT
fi


if [[ $1 == *.zip ]]; then
    echo Chroot
    #perl -e 'print crypt("ansible", "salt"),"\n"'
    sudo chroot ~/mnt/ /bin/bash << "EOT"
useradd -m -s $(which bash) -p sa/o2qVjeFay2 -G sudo ansible
gpasswd -d ubuntu sudo
mkdir -p /home/ansible/.ssh
cat /id_rsa.pub > /home/ansible/.ssh/authorized_keys
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/
rm /id_rsa.pub
echo "pending-setup" > /etc/hostname
echo "#!/bin/bash" > /notifyer
echo "while true; do     sleep 60;     echo \`ip addr\` | /v6UdpMcastClt ff03::22 9999 ; done" >> /notifyer
chmod +x /notifyer
chmod +x /v6UdpMcastClt
systemctl enable notifyer.service
EOT
fi



if [[ $1 == *.tar.gz ]]; then
    echo Chroot
    #perl -e 'print crypt("ansible", "salt"),"\n"'
    sudo chroot ~/mnt/ /bin/bash << "EOT"
useradd -m -s $(which bash) -p sa/o2qVjeFay2 ansible
mkdir -p /home/ansible/.ssh

cat /id_rsa.pub > /home/ansible/.ssh/authorized_keys
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
chown -R ansible:ansible /home/ansible/
rm /id_rsa.pub
echo "pending-setup" > /etc/hostname
echo "#!/bin/bash" > /notifyer
echo "while true; do     sleep 60;     echo \`ip addr\` | /v6UdpMcastClt ff03::22 9999 ; done" >> /notifyer
chmod +x /notifyer
chmod +x /v6UdpMcastClt
systemctl enable notifyer.service
EOT
    echo Detach loop
    sudo losetup --detach-all
    echo Unmount mnt / boot
    sudo umount ~/mnt/boot

fi

echo Unmount Image
sudo umount ~/mnt

echo Remove Mountpoint
sudo rm -rf ~/mnt



echo -e "\e[32mFinished, pending-setup.img created\e[0m"

mv ansible.img pending-setup.img

echo Run Mcast Server: ./v6UdpMcastSrv ff03::22 9999
