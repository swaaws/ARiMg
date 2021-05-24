
<p align="center">
    <img src="logo.svg" width="400">
</p>

# Welcome to ARiMg

## What's ARiMg?

AR' iM' g'  is a helper that includes everything* needed to
modify SD Card Images according to the [Acorn RISC Machine (ARM)](https://en.wikipedia.org/wiki/ARM_architecture) Platform.
*bsdtar, Golang and GNU not included


## Preamble
In most cases you need to setup a arm (raspberry like) host.
You get an img from the Website and flashing it with _**dd**_ to the sd card
you plug network, keyboard, mouse, display and power. All fine?
Then you don't need this tool.
But what is if you don't have a keyboard, mouse and display because of idleness?
-> This tool is your _**MASTER Branch**_  

You get an Provisioning user called: _**ansible**_  with the password _**ansible**_
and if the Host is booted up it announce over Multicast with his ip addr output.
Your login looks like ssh ansible@[ip from nc -u -l 9999 or ./v4UdpMcastSrv]  


## What's open
* Ipv6 multicast announcing
* save recognition of the pattern rootfs<->MBR/GPT 
* permit password login
* automatische provisionirung der erkannten hosts durch ansible
* GPT support




## Download Structure

In most cases the Operating System comes as a Compressed File with an Image(img)
or as a Plain Root Directory(rootfs):

- Plain Root Directory in ... (Your Flavour Compression Algorithm)
  i.e. ArchLinuxARM-rpi-2-latest.tar.gz
- SD Card img packed in ... (Your Flavour Compression Algorithm)
  i.e. ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
- ...

## Image Structur

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

## Supported Images


_**ubuntu  arm64 raspi**_
- `b3a80ce2979a0841c06831475993cfff80e5614c` 21.04 preinstalled-server

_**Debian 10.3-iot-armhf**_
- `164e1bdd70d743eda3395444a5a5bbdedbab5b04` bone 4gb
- `8be911fb79156cf4f80bc1451f887883359bca46` bone-eMMC-flasher 4gb


_**Raspbian armhf**_
- `f30f9bb907a33736b7d7543da80fac3b1d6c6651` buster lite

_**ArchLinuxARM**_
- `4f0fe7bc9944ca244c3f719da46386200d94a253` rpi-2 (RPI 3) latest



## Getting Started

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

_**3. Create the modifyed img**_
```bash
# Username: ansible
# Password: ansible
./feasibility.bash ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz

#If you Deploy more than one at the same Time: (Infinite Multicast Server)
./cluster_deploy.bash

```

_**4. Additional Ansible steps**_
```text
Throught Ansible:
* Disable Passwordauth
* Disable Root Login
* Change Password


```
