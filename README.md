
<p align="center">
    <img src="logo.svg" width="400">
</p>

# 🙏Welcome to ARiMg🙏

## 🧐 What's ARiMg? 🧐

AR' iM' g'  is a helper to modify SD Card Images according to the [Acorn RISC Machine (ARM)](https://en.wikipedia.org/wiki/ARM_architecture) Platform to find the deployed clients over Network.



## 📓 Preamble 📓
In some case you need to setup many arm (raspberry like) hosts.
You get an image from a website and flash it with _**dd**_ to the sd card(or netboot...)
you plug network, keyboard, mouse, display and power. All fine?
Then you don't need this tool.
But what is if you don't have a keyboard, mouse and display because of idleness?
-> This tool can _**fit**_

You get an provisioning user called: _**spinup**_  with the password _**spinup**_
and if the Host is booted up it announce over ssh to your deploy host with usefull output.

The client places a file called pending-[macaddress] in the host home directory where the img was modifyed (or the given ip with -i/--ip).
Your login looks like ssh spinup@[ip from _**~/pending-***_ ]

Over ansible-playbooks all changes where reverted and a user called _**ansible**_ will be created.


## ⚡️ For the fast ones ⚡️
```bash
./arimg -h
usage: arimg [-c] [-i|--ip 2001:DB8::1]
             [-u|--user spinup] [-k|--key .ssh/id_rsa]
             [-r|--reversekey .ssh/reversekey_rsa] [-o|--output deploy.img] input

./arimg ArchLinuxARM-rpi-2-latest.tar.gz
# know the layout of your file: 1(Partition table) , 2(Compressed root): 2 (ArchLinuxArm example)
# want shell access befor finish: n/y

./arimg -c # Catch hosts from network
----------------
Hosts in File: 0
Press [a] generate ansible host inventory.
Press [h] generate hosts file.
Press [n] clear file.
Press [q] quit


# Ansible steps
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ~/pending.ansible.yaml ~/github/ARiMg/ansible/01_spinup.yml
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ~/pending.ansible.yaml ~/github/ARiMg/ansible/02_apt_upgrade.yml
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ~/pending.ansible.yaml ~/github/ARiMg/ansible/03_finish.yml
ansible all -i pending.ansible.yaml --become -a "poweroff" -u ansible

```

_**Scroll down look at point 6. Additional Ansible steps**_  

## 📖 What's open 📖

* automatic provision thought <s>Ansible</s>
* GPT support
* Support ISO's with Preseed File \*-\*
* expand fs
* Set Workdirectory to /tmp
* (dream) use multicast for anounce
* Reorganise: chart. md # Depenency Relationship Diagram

## Operating system peculiarities
* ArchLinuxARM dosnt have sudo. so ansible cant work at this point. use --ask-become

## Download Structure

In most cases the Operating System comes as a Compressed File as an Image(img)
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

```text
someDistro.rootfs
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



## Manpage
```manpage
NAME
      arimg - modify operating system images

SYNOPSIS
      arimg [-c] | [-i|--ip 2001:DB8::1]
            [-u|--user spinup] [-k|--key .ssh/id_rsa]
            [-r|--reversekey .ssh/reversekey_rsa] [-o|--output deploy] input

DESCRIPTION
      arimg is a helper to modify SD Card Images
            according to the ARM Platform.

      The options are:
      -c    Catch hosts from network (interactive)

      -i    Specify the ip where the deploy host connect over ssh. ATP: ipv6 only
            (Default: the host ipv6 address where arimg has build the image)

      -u    Specify the user where the deploy host connect over ssh.
            (Current user where arimg has build the image)

      -k    Specify a file which used to provide an rsa key for user spinup.
            (The default is ~/.ssh/id_rsa). Note: Ansible use ~/.ssh/id_rsa

      -r    Specify a file which used to allow connect to the deploy host.
            (The default is ~/.ssh/reverse_rsa).

      -o    name the resulting image
            (default [imputname]-spinup.img)
```


## 🏁 Getting Started 🏁

_**0. Other**_
You search for custom iso[^2] or img[^1] creation?

_**1. Download the Repo**_
```bash
git clone https://github.com/swaaws/ARiMg.git
```

_**2. Download a Operating System**_
```bash
#Notice: Needs the Same Architecture as your Host
#Workflow:  Run This Repo on an Raspberry and scp the Final img (or dd the resulting img to a second sd card)
wget https://cdimage.ubuntu.com/releases/21.04/release/ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
```

_**3. Start Deployment**_
```bash
ubuntu@raspberry:~$ ARiMg/arimg ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
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
Copy RSA to rootfs
Create notifyer.service
Copy notifyer.service to rootfs
Remove notifyer.service
Create netconfig
Copy netconfig to rootfs
Remove netconfig
Create modification.txt
Copy modification.txt to rootfs
Create finish.bash
Copy finish.bash to rootfs
Create notifyer
Copy notifyer to rootfs
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
ubuntu@raspberry:~$ ARiMg/arimg -c # Catch hosts from network
----------------
Hosts in File: 0
Press [a] generate ansible host inventory.
Press [h] generate hosts file.
Press [n] clear file.
Press [q] quit
a
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ~/pending.ansible.yaml ~/github/ARiMg/ansible/01_spinup.yml
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ~/pending.ansible.yaml ~/github/ARiMg/ansible/02_apt_upgrade.yml
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ~/pending.ansible.yaml ~/github/ARiMg/ansible/03_finish.yml

q
ubuntu@raspberry:~$
```

_**6. Additional Ansible steps**_
```text
Throught:
* Disable Passwordauth - ansible/01_spinup.yml
* Disable Root Login - ansible/01_spinup.yml
* Add Ansible management User - ansible/01_spinup.yml
* Remove spinup User - ansible/03_finish.yml
* Run finish.bash on nodes - ansible/03_finish.yml
* Change Password
* Some OS'es ships default user keep an eye on it


```



[^1]: **Genimage** - The Image Creation Tool
[^2]: **CUBIC** - Custom Ubuntu ISO Creatortted*.
