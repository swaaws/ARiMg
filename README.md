
<p align="center">
    <img src="logo.svg" width="400">
</p>

# 🙏Welcome to ARiMg🙏

## 🧐 What's ARiMg? 🧐

AR' iM' g'  is a helper that includes everything* needed to
modify SD Card Images according to the [Acorn RISC Machine (ARM)](https://en.wikipedia.org/wiki/ARM_architecture) Platform.
*dependencies not included


## 📓 Preamble 📓
In some case you need to setup many arm (raspberry like) hosts.
You get an img from the Website and flashing it with _**dd**_ to the sd card
you plug network, keyboard, mouse, display and power. All fine?
Then you don't need this tool.
But what is if you don't have a keyboard, mouse and display because of idleness?
-> This tool can Fits your _**Needs**_  

You get an Provisioning user called: _**spinup**_  with the password _**spinup**_
and if the Host is booted up it announce over ssh to your deploy host with usefull output.
Your login looks like ssh spinup@[ip from ./deploy_cache.bash]


## ⚡️ For the fast ones ⚡️
```bash
./deploy_start.bash ArchLinuxARM-rpi-2-latest.tar.gz
# know the layout of your file: 1(Partition table) , 2(Compressed root)
# 2 (ArchLinuxArm example)
# want shell access befor finish: n/y
./deploy_cache
./deploy_done      <- !!!!Important!!!!
```
_**Scroll down look at point 6. Additional Ansible/Puppet/Chef steps**_  

## 📖 What's open 📖
* permit password login
* automatic provision thought Ansible/Puppet/Chef
* GPT support


## Download Structure

In most cases the Operating System comes as a Compressed File with an Image(img)
or as a Plain Root Directory(rootfs):

- Plain Root Directory in ... (Your Flavour Compression Algorithm)
  i.e. ArchLinuxARM-rpi-2-latest.tar.gz
- SD Card img packed in ... (Your Flavour Compression Algorithm)
  i.e. ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
- ...

## Image Structure

_**SD Card Img**_
```text
 SD Card img (.img, .raw, ...)
|------------------------------------------------------------------------------|
|   Patition table msdos                                               3900MB  |
|  |-------------------------------------------------------------------------| |
|  |   Boot Partition fat32                                          257MiB  | |
|  |  |--------------------------------------------------------------------| | |
|  |  | /                                                                  | | |
|  |  | | kernel                                                           | | |
|  |  | | initramfs                                                        | | |
|  |  | | ...                                                              | | |
|  |  |                                                                    | | |
|  |  |--------------------------------------------------------------------| | |
|  |                                                                         | |
|  |   Root Partition ext4                                             100%  | |
|  |  |--------------------------------------------------------------------| | |
|  |  | /                                                                  | | |
|  |  | | bin                                                              | | |
|  |  | | etc                                                              | | |
|  |  | |    /                                                             | | |
|  |  | |     | fstab [mount ext4 to /] [mount fat32 to /boot]             | | |
|  |  | | ...                                                              | | |
|  |  |                                                                    | | |
|  |  |                                                                    | | |
|  |  |--------------------------------------------------------------------| | |
|  |-------------------------------------------------------------------------| |
|------------------------------------------------------------------------------|
```

_**Plain Root Directory**_
.rootfs.(Flavour Compression)
```text
/
 | bin
 | dev
 | etc
 | mnt
```

## 🎗 Supported Images 🎗


_**ubuntu  arm64 raspi**_
- `b3a80ce2979a0841c06831475993cfff80e5614c` 21.04 preinstalled-server

_**Debian 10.3-iot-armhf**_
- `164e1bdd70d743eda3395444a5a5bbdedbab5b04` bone 4gb
- `8be911fb79156cf4f80bc1451f887883359bca46` bone-eMMC-flasher 4gb


_**Raspbian armhf**_
- `f30f9bb907a33736b7d7543da80fac3b1d6c6651` buster lite

_**ArchLinuxARM**_
- `4f0fe7bc9944ca244c3f719da46386200d94a253` rpi-2 (RPI 3) latest



## 🏁 Getting Started 🏁

_**1. Download the Repo**_
```bash
git clone https://github.com/swaaws/ARiMg.git
```

_**2. Download a Operating System**_
```bash
#Notice: Needs the Same Architecture as your Host
#Workflow:  Run This Repo on an Raspberry and scp the Final img (or dd the img to a second sd card)
wget https://cdimage.ubuntu.com/releases/21.04/release/ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
```

_**3. Start Deployment**_
```bash
ubuntu@raspberry:~$ ./deploy_start.bash ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
Chosse Filedesign: [1] - sd_card-image, [2] - plain_rootfs: 1
want shell access to img? [y] - yes, [n] - no: y
get file info
shasum: b3a80ce2979a0841c06831475993cfff80e5614c
File: ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
Compression detected: XZ
Found RSA Publickey
Found Reverse RSA Publickey
Create Duplicate
Decompress xz
...
Create Mountpoint
Start bit for root: 526336
Sector Size: 512
Mountbit: 269484032
Mount Image
Mount Suxxxxxess
Copy RSA to root fs
Create notifyer.service
Copy notifyer.service to Root fs
Remove notifyer.service
Create netconfig
Copy netconfig to Root fs
Remove netconfig
Create modification.txt
Copy modification.txt to Root fs
Create finish.bash
Copy finish.bash to Root fs
Create notifyer
Copy modification.txt to Root fs
Chroot
useradd: user 'spinup' already exists
Created symlink /etc/systemd/system/multi-user.target.wants/notifyer.service → /etc/systemd/system/notifyer.service.
interactive shell! CTRL-d if done
  root@raspberry:/# cat /etc/os-release
    NAME="Ubuntu"
    VERSION="21.04 (Hirsute Hippo)"
    ID=ubuntu
    ID_LIKE=debian
    PRETTY_NAME="Ubuntu 21.04"
    VERSION_ID="21.04"
    HOME_URL="https://www.ubuntu.com/"
    SUPPORT_URL="https://help.ubuntu.com/"
    BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
    PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
    VERSION_CODENAME=hirsute
    UBUNTU_CODENAME=hirsute
  root@raspberry:/#
    exit/CTRL-d
Unmount Image
Remove Mountpoint
Finished, ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz-spinup.img created

```
_**4. Cache Hosts**_
```bash
# Username: spinup
# Password: spinup
ubuntu@raspberry:~$ ./deploy_cache.bash
Hosts in File: 3
hostname: pending-setup gateway: 2001:DB8::/32 global6: 2001:DB8::1/32 link-local: fe80:DB8::/32 mac_addr: ff:ff:ff:ff:ff:ff status: running failed: 0 units
hostname: pending-setup gateway: 2001:DB8::/32 global6: 2001:DB8::2/32 link-local: fe80:DB8::/32 mac_addr: ff:ff:ff:ff:ff:ff status: running failed: 0 units
hostname: pending-setup gateway: 2001:DB8::/32 global6: 2001:DB8::3/32 link-local: fe80:DB8::/32 mac_addr: ff:ff:ff:ff:ff:ff status: running failed: 0 units
...
```

_**5. Finish Deployment**_
```bash
# This Step is important because simple password -> ssh key to your deployment host
ubuntu@raspberry:~$ ./deploy_done.bash

```

_**6. Additional Ansible/Puppet/Chef steps**_
```text
Throught:
* Disable Passwordauth
* Run finish.bash on nodes
* Add Ansible management User
* Remove spinup User
* Disable Root Login
* Change Password
* Some OS'es ships default user keep an eye on it

```
