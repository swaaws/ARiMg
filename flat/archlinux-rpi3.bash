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
    sudo umount mnt
    sudo rm -rf ~/mnt

fi

if [ -f ~/spinup.img ]; then
    echo Old spinup.img Removed
    sudo rm -rf ~/spinup.img
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



if [[ $compression == gzip ]]; then

    echo Create Mountpoint
    mkdir ~/mnt

    echo Create spinup.img
    sudo dd of=~/spinup.img seek=3900M bs=1 count=0

    echo Create Patition Table
    sudo parted ~/spinup.img mktable msdos

    echo Create Boot  Patition
    sudo parted ~/spinup.img mkpart primary fat32 2048s 257MiB

    echo Create Root Patition
    sudo parted ~/spinup.img mkpart primary ext4 257MiB 100%

    echo Attach spinup.img to loop Device
    loop=`sudo losetup --find --partscan --show spinup.img`

    echo Create vfat on Boot Patition
    sudo mkfs.vfat -F 32 -n BOOT "${loop}p1"

    echo Create ext4 on Root Partition
    sudo mkfs.ext4 -L rootfs "${loop}p2"

    echo Mount Root Patition
    sudo mount "${loop}p2" ~/mnt/

    echo Mount Boot Patition
    sudo mkdir ~/mnt/boot
    sudo mount "${loop}p1" ~/mnt/boot

    echo Decompress the file \(needs time...\)
    sudo bsdtar -xpf ~/$1 -C ~/mnt

    sync

fi      






#--------------------------------------------------------#
# Raspberry PI 3:
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
Add User: spinup (pw: spinup)
Added Directory: /home/spinup/.ssh
Added File: /home/spinup/modification.txt
Added File: /home/spinup/.ssh/authorized_keys
Set Hostname: "pending-setup" > /etc/hostname
Systemd Service Enabled: /etc/systemd/system/notifyer.service
EOF

echo Copy modification.txt to Root fs
sudo cp -f ~/modification.txt ~/mnt/modification.txt

echo Remove modification.txt
rm  ~/modification.txt


if [[ $compression == gzip ]]; then
    echo Chroot
    #perl -e 'print crypt("spinup", "salt"),"\n"'
    sudo chroot ~/mnt/ /bin/bash << "EOT"
useradd -m -s $(which bash) -p sa/o2qVjeFay2 spinup
mkdir -p /home/spinup/.ssh
cat /id_rsa.pub > /home/spinup/.ssh/authorized_keys
mv /modification.txt /home/spinup/modification.txt
chmod 700 /home/spinup/.ssh
chmod 600 /home/spinup/.ssh/authorized_keys
chown -R spinup:spinup /home/spinup/
rm /id_rsa.pub
echo "pending-setup" > /etc/hostname
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

echo -e "\e[32mFinished, $1-spinup.img created\e[0m"

mv spinup.img $1-spinup.img

