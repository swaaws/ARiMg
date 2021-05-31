#!/bin/bash
#https://www.pugetsystems.com/labs/hpc/Note-Auto-Install-Ubuntu-with-Custom-Preseed-ISO-1654/ iso's ^:/
programname=$0

if test "$#" -ne 1; then
    echo "usage: $programname ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz"
    exit
fi


read -p "Chosse Filedesign: [1] - sd_card-image, [2] - plain_rootfs: " filedesign
read -p "want shell access to img? [y] - yes, [n] - no: " shellaccess


compression=`file $1 | awk '{print $2}'`
echo get file info
echo shasum: `shasum $1 | awk '{print $1}'`
echo File: $1
echo Compression detected: $compression

if [ -d ~/mnt ]; then
    echo Remove mnt
    sudo umount mnt/boot
    sudo umount mnt
    sudo rm -rf ~/mnt

fi

if [ -f ~/spinup.img ]; then
    echo Removed spinup.img
    sudo rm -rf ~/spinup.img
fi


if [ -f ".ssh/id_rsa.pub" ]; then
    echo  Found RSA Publickey;
else
    echo Please run ssh-keygen
    exit 1
    # echo Generate RSA;
    # ssh-keygen -q -N "";
fi

if [ -f ".ssh/reverse_rsa.pub" ]; then
    echo  Found Reverse RSA Publickey;
else
    echo Generate remote sshkey
    ssh-keygen -f .ssh/reverse_rsa  -N ""
    cat .ssh/reverse_rsa.pub >> .ssh/authorized_keys
fi



#sd_card-image
if [[  $filedesign == 1 ]]; then
    case $compression in

        Zip)
            echo Decompress Zip
            unzip $1 -d ~/temp
            mv ~/temp/*.img ~/spinup.img
            rm -rf temp
            ;;

        XZ)
            echo Create Duplicate
            cp $1 ~/spinup.img.xz

            echo Decompress xz
            xz --decompress ~/spinup.img.xz
            ;;

        gzip)
            exit 1

            echo Decompress gzip
            ;;

        *)
            echo unknown compression: $compression
            exit 1
            ;;
    esac
    echo Create Mountpoint
    mkdir ~/mnt

    startbit=`fdisk -l ~/spinup.img -o start,id,type | grep "83 Linux" | awk '{print $1}'`
    echo Start bit for root: $startbit
    sectorsize1=`fdisk -l ~/spinup.img | grep "I/O size" | awk '{print $4}'`
    echo Sector Size: $sectorsize1

    echo Mountbit: $(($startbit*$sectorsize1))

    #   526336  *    512
    # Start Bit * Sector Size

    echo Mount Image
    sudo mount -o loop,offset=$(($startbit*$sectorsize1)) ~/spinup.img ~/mnt

fi


#plain_rootfs
if [[  $filedesign == 2 ]]; then


    echo Create Mountpoint
    mkdir ~/mnt

    echo Create spinup.img
    sudo dd of=~/spinup.img seek=3900M bs=1 count=0 status=none

    echo Create Patition Table
    sudo parted ~/spinup.img mktable msdos

    echo Create Boot  Patition
    sudo parted ~/spinup.img mkpart primary fat32 2048s 257MiB

    echo Create Root Patition
    sudo parted ~/spinup.img mkpart primary ext4 257MiB 100%

    echo Attach spinup.img to loop Device
    loop=`sudo losetup --find --partscan --show spinup.img`

    echo Create vfat on Boot Patition
    sudo mkfs.vfat -F 32 -n BOOT "${loop}p1" > /dev/null

    echo Create ext4 on Root Partition
    sudo mkfs.ext4 -L rootfs "${loop}p2" | grep ,

    echo Mount Root Patition
    sudo mount "${loop}p2" ~/mnt/

    echo Mount Boot Patition
    sudo mkdir ~/mnt/boot
    sudo mount "${loop}p1" ~/mnt/boot
    case $compression in

        Zip)
            exit 1
            echo Decompress Zip \(needs time...\)
            unzip $1 -d ~/mnt
            ;;

        XZ)
            exit 1
            echo Decompress the file \(needs time...\)
            xz --decompress $1 ~/mnt
            ;;

        gzip)

            echo Decompress the file \(needs time...\)
            sudo bsdtar -xpf ~/$1 -C ~/mnt
            ;;

        *)
            echo unknown compression
            echo Remove mnt
            sudo umount mnt/boot
            sudo umount mnt
            sudo rm -rf ~/mnt
            sudo rm -rf ~/spinup.img

            exit 1
            ;;
    esac


    sync
fi


#--------------------------------------------------------#
# Raspberry PI 3:
# 269484032 b3a80ce2979a0841c06831475993cfff80e5614c Ubuntu    ARM64 ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
#   4194304 164e1bdd70d743eda3395444a5a5bbdedbab5b04 Debian    ARMHF bone-debian-10.3-iot-armhf-2020-04-06-4gb.img.xz
#   4194304 8be911fb79156cf4f80bc1451f887883359bca46 Debian    ARMHF bone-eMMC-flasher-debian-10.3-iot-armhf-2020-04-06-4gb.img.xz
#    532480 f30f9bb907a33736b7d7543da80fac3b1d6c6651 Debian    ARMHF 2021-03-04-raspios-buster-armhf-lite.zip
#    532480 5e402402984b4f9216b2a3eff1f830d169afd4ea Debian    ARMHF 2021-05-07-raspios-buster-armhf-lite.zip
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
sudo mkdir mnt/.ssh
sudo cp -f ~/.ssh/reverse_rsa ~/mnt/id_rsa

echo Remove notifyer.service
rm  ~/notifyer.service



echo Create netconfig
cat <<'EOF' >> ~/netconfig
#!/bin/bash

interface=`ip -o -6 route show to default | awk '{print $5}'`
echo hostname: `hostname` gateway: `ip -o -6 route show to default \
| awk '{print $3}'` global6: `ip addr show $interface | grep global \
| grep inet6 | awk '{print $2}'` link-local: `ip addr show $interface \
| grep link | grep inet6 | awk '{print $2}'` mac_addr: `ip addr show $interface \
| grep ether  | awk '{print $2}'` status: `systemctl status | grep "  State: " \
| awk '{print $2}'` failed: `systemctl status | grep "  Failed: " | awk '{print $2}'` units
EOF

echo Copy netconfig to Root fs
sudo cp -f ~/netconfig ~/mnt/

echo Remove netconfig
rm  ~/netconfig

echo Create modification.txt
cat <<'EOF' >> ~/modification.txt
Add User: spinup (pw: spinup)
Added Directory: /home/spinup/.ssh
Added File: /netconfig
Host generated File: /netconfig_data
Added File: /notifyer
Added File: /finish.bash
Added File: /home/spinup/modification.txt
Added File: /home/spinup/.ssh/authorized_keys
Set Hostname: "pending-setup" > /etc/hostname
Systemd Service Enabled: /etc/systemd/system/notifyer.service
EOF
echo Copy modification.txt to Root fs
sudo cp -f ~/modification.txt ~/mnt/modification.txt
rm  ~/modification.txt



echo Create finish.bash
cat <<'EOF' >> ~/finish.bash
systemctl disable notifyer.service
systemctl stop notifyer.service
rm /netconfig /netconfig_data /notifyer /etc/systemd/system/notifyer.service /home/spinup/modification.txt
echo "finished-setup" > /etc/hostname
rm finish.bash
EOF
echo Copy finish.bash to Root fs
sudo cp -f ~/finish.bash ~/mnt/finish.bash
rm  ~/finish.bash






myip=`ip addr | grep inet6 | grep global |  awk '{print $2}' | rev | cut -c4- | rev`
myuser=`whoami`
echo Create notifyer
echo "#!/bin/bash" > ~/notifyer
echo "while true; do" >> ~/notifyer
echo "sleep 60;" >> ~/notifyer
echo "/netconfig > /netconfig_data;" >> ~/notifyer
echo "scp -o 'StrictHostKeyChecking no' -i /root/.ssh/id_rsa /netconfig_data $myuser@[$myip]:~/pending ;" >> ~/notifyer
echo "done" >> ~/notifyer
echo Copy modification.txt to Root fs
sudo cp -f ~/notifyer ~/mnt/notifyer
rm  ~/notifyer


echo Chroot
#perl -e 'print crypt("spinup", "salt"),"\n"'
sudo chroot ~/mnt/ /bin/bash << "EOT"
useradd -m -s $(which bash) -p saurX9qN91.BQ spinup
useradd -m -s $(which bash) -p saurX9qN91.BQ -G sudo spinup
mkdir -p /home/spinup/.ssh
cat /id_rsa.pub > /home/spinup/.ssh/authorized_keys
mv /modification.txt /home/spinup/modification.txt
mkdir /root/.ssh/
mv /id_rsa /root/.ssh/id_rsa
chmod 700 /root/.ssh/id_rsa
chmod 700 /home/spinup/.ssh
chmod 600 /home/spinup/.ssh/authorized_keys
chown -R spinup:spinup /home/spinup/
rm /id_rsa.pub
echo "pending-setup" > /etc/hostname
chmod +x /notifyer
chmod +x /netconfig
systemctl enable notifyer.service
EOT

if [[  $shellaccess == y ]]; then
echo interactive shell! CTRL-d if done
bash -c "sudo chroot ~/mnt/"
fi


if [[  $filedesign == 2 ]]; then
echo Detach loop
sudo losetup --detach-all
sudo losetup -d `losetup -a | grep spinup.img | awk -F ":" '{print $1}'`
echo Unmount mnt / boot
sudo umount ~/mnt/boot

fi

echo Unmount Image
sudo umount ~/mnt

echo Remove Mountpoint
sudo rm -rf ~/mnt


if [ -f ~/$1-spinup.img.old ]; then
echo Removed $1-spinup.img.old
sudo rm -rf ~/$1-spinup.img.old
fi
mv $1-spinup.img $1-spinup.img.old
mv spinup.img $1-spinup.img

echo -e "\e[32mFinished, $1-spinup.img created\e[0m"
