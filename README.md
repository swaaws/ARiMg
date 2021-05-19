
<p align="center">
    <img src="https://upload.wikimedia.org/wikipedia/commons/7/77/Arm_logo_2017.svg" width="400">
</p>

# Welcome to ARiMg

## What's ARiMg?

AR' iM' g'  is a helper that includes everything* needed to
modify SD Card Images according to the [Acorn RISC Machine (ARM)](https://en.wikipedia.org/wiki/ARM_architecture) Platform. *bsdtar, Golang and GNU not included

## Download Structure

In most cases the Operating System comes as a Download:

- Plain Root Directory in ... (Your Flavour Compression Algorithm) i.e. ArchLinuxARM-rpi-2-latest.tar.gz
- SD Card img packed in ... (Your Flavour Compression Algorithm) i.e. ubuntu-21.04-preinstalled-server-arm64+raspi.img.xz
- ...

## Supported Images

Successfully Testet Images with there shasum

_**ubuntu  arm64 raspi**_
- `b3a80ce2979a0841c06831475993cfff80e5614c` 21.04 preinstalled-server

_**Debian 10.3-iot-armhf**_
- `164e1bdd70d743eda3395444a5a5bbdedbab5b04` bone 4gb
- `8be911fb79156cf4f80bc1451f887883359bca46` bone-eMMC-flasher 4gb


_**Raspbian armhf**_
- `f30f9bb907a33736b7d7543da80fac3b1d6c6651` buster lite

_**ArchLinuxARM**_
- `4f0fe7bc9944ca244c3f719da46386200d94a253` rpi-2 (RPI 3) latest


## Image Structur

_**SD Card Img**_
```text
 .img, .raw
|------------------------------------------------------------------------------|
|   Patition table msdos                                                       |
|  |-------------------------------------------------------------------------| |
|  |   Boot Partition fat32                                                  | |
|  |  |--------------------------------------------------------------------| | |
|  |  | /                                                               |  | | |
|  |  | | kernel                                                        |  | | |
|  |  | | initramfs                                              257MiB |  | | |
|  |  | | ...                                                           |  | | |
|  |  |                                                                 |  | | |
|  |  |--------------------------------------------------------------------| | |
|  |                                                                         | |
|  |   Root Partition ext4                                                   | |
|  |  |--------------------------------------------------------------------| | |
|  |  | /                                                               |  | | |
|  |  | | bin                                                           |  | | |
|  |  | | etc                                                           |  | | |
|  |  | |    /                                                          |  | | |
|  |  | |     | fstab [mount ext4 to /] [mount fat32 to /boot]          |  | | |
|  |  | | ...                                                           |  | | |
|  |  |                                                                 |  | | |
|  |  |                                                            100% |  | | |
|  |  |                                                                 |  | | |
|  |  |                                                                 |  | | |
|  |  |                                                                 |  | | |
|  |  |                                                                 |  | | |
|  |  |                                                                 |  | | |
|  |  |--------------------------------------------------------------------| | |
|  |-------------------------------------------------------------------------| |
|------------------------------------------------------------------------------|
```

## Getting Started

Needs to run on the same ARCH as the input Image: Raspberry 3.img > Raspberry 3 Host
