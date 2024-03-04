# PXE server

[Docker](https://docker.com) container with a PXE server. To accomplish this is configured a container with:
* [PXELinux](https://wiki.syslinux.org/wiki/index.php?title=PXELINUX) - The PXE server. `BIOS` and `UEFI` support;
* [DNSmasq](https://thekelleys.org.uk/dnsmasq/doc.html) - for DHCP and TFTP server that will serve the PXE files. There is also a DNS server;
* [Samba](https://www.samba.org/) (for Windows OS) and NFS (for Unix-like OS) to serve the image files;

## Setup

As you will run a DHCP server, you must configure your local network parameters.

> :warning: You must disable any DHCP/DNS server service if there is one running at your local network.

Open the `scripts/config.sh` script and change the following variables:
```bash
# Output directory of configured files
output_dir=out
# The images directory that will be mapped inside de containers
images_dir=/home/rnascunha/data/images
# Your own IP. Must be a fixed value (as you will be a DHCP server)
server_ip="192.168.15.201"
# Network router IP
router_ip="192.168.15.1"
# First address serverd by the DHCP server
dhcp_ini="192.168.15.10"
# Last address serverd by the DHCP server
dhcp_end="192.168.15.200"
# Network mask
netmask="255.255.255.0"
# DHCP lease time
lease_time="12h"
# Local network domain
domain=homeap
```
And run:
```bash
$ ./scripts/config.sh
```
This will create the output directory (defaulted to `out`) with the configured files.

You can also change the parameters via command line. To see all options:
```bash
$ ./scripts/config.sh -h
config.sh -h|
          [-i <images_dir>]
          [-s <server_ip>]
          [-r <router_ip>]
          [-c <dhcp-ini>,<dhcp-end>]
          [-n <netmask>]
          [-l <lease_time>]
          [-d <domain>]
          [-t <template_dir>]
          [-o <output_dir>]
```

### Images

You need to download and unpack all image files of the tools/OSs that you want to boot at a directory. Set this folder at the `.env` file (done by the `scrpits/config.sh` script), `IMAGES_PATH` property. This folder will be mapped inside the container to the `/tftpboot/images` directory.

You also need to configure the menu and boot parameters of the images that you download and put at `tftpboot/pxelinux.cfg/`. There is already some configurations there that you can use as reference. To check all options, see [SYSLINUX](https://wiki.syslinux.org/wiki/index.php?title=SYSLINUX#How_do_I_Configure_SYSLINUX.3F).

### DNSMasq

The container must run a DHCP server at your local network, so it will be responsible to provide the correct network parameters to other devices. The `etc/dnsmasq.conf` must be configured accordingly. The most important are:
```bash
# The range of ip address 
dhcp-range=192.168.0.10,192.168.0.200,255.255.255.0,12h
# The default gateway
dhcp-option=option:router,192.168.0.1
```
If you want to fix the IP of some machine, you can:
```bash
dhcp-host=ac:74:b1:9a:05:d3,cockpit,192.168.0.3,infinite
```

More options see [dnsmasq.conf](https://thekelleys.org.uk/gitweb/?p=dnsmasq.git;a=blob;f=dnsmasq.conf.example).

> :warning: As you are going to run your own DHCP and DNS server, you must disable this services if running at your network.

### Others

#### Ubuntu

At ubuntu, disable the `systemd-resolved` service (DNS):
```bash
$ systemctl stop systemd-resolved
$ systemctl disable systemd-resolved
```
Also install [Docker](https://docker.com) at your device. See how [here](https://docs.docker.com/engine/install/ubuntu/).

## Run Container

After everything setup, go to the output directory (defaulted to `out`):
```bash
$ cd out/
```
As root, type:
```bash
$ docker compose up
```
This will bring up the containers. If will want to run it as a daemon add the `-d` option:
```bash
$ docker compose up -d
```
To bring it down:
```bash
$ docker compose down
```

## Reference

* [SYSLINUX](https://wiki.syslinux.org/wiki/index.php?title=SYSLINUX)
* [Set up PXE](https://medium.com/jacklee26/set-up-pxe-server-on-ubuntu20-04-and-window-10-e69733c1de87): a good article about setting up PXE server, especially part 3, that describes how to create a Windows PE ISO to boot Windows system.
* [Clonezilla](https://clonezilla.org/livepxe.php)
* [GParted](https://gparted.org/livepxe.php)
* [erichough/nfs-server](https://github.com/ehough/docker-nfs-server): docker image used to serve NFS.