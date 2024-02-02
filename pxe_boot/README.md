# PXE server

Docker container with a PXE server. To accomplish this configured a container with:
* [PXELinux](https://wiki.syslinux.org/wiki/index.php?title=PXELINUX) - The PXE server. `BIOS` and `UEFI` support;
* [DNSmasq](https://thekelleys.org.uk/dnsmasq/doc.html) - for DHCP and TFTP server that will serve the PXE files. It also have a DNS server;
* [Samba](https://www.samba.org/) (for Windows OS) and NFS (for Unix-like OS) to serve the image files;

## Setup

### Images

You eed to download and unpack all the images files of the tools or OSs that you want to boot at a directory. Set this folder at the `.env` file, `IMAGES_PATH` property. This folder will be mapped inside the container to the `/tftpboot/images` directory.

You also need to configure the menu and boot parameters of the images that you download and put at `tftpboot/pxelinux.cfg`. There is already some configurations there that you can use as reference. To all check all options, see [SYSLINUX](https://wiki.syslinux.org/wiki/index.php?title=SYSLINUX#How_do_I_Configure_SYSLINUX.3F).

### DNSMasq

The container must run a DHCP server at your network, so it will be responsible to provide the correct network parameters to other devices. The `etc/dnsmasq.conf` must be configured accordingly. The most important are:
```
# The range of ip address 
dhcp-range=192.168.0.10,192.168.0.200,255.255.255.0,12h
# The default gateway
dhcp-option=option:router,192.168.0.1
```
If you want to fix the IP of some machine, you can:
```
dhcp-host=ac:74:b1:9a:05:d3,cockpit,192.168.0.3,infinite
```

More options see [dnsmasq.conf](https://thekelleys.org.uk/gitweb/?p=dnsmasq.git;a=blob;f=dnsmasq.conf.example).

> :warning: As you are going to run your own DHCP and DNS server, you must disable this services if running at your network.

### Others

#### Ubuntu

At ubuntu, you must disable the `systemd-resolved` service (DNS):
```
$ systemctl stop systemd-resolved
$ systemctl disable systemd-resolved
```
You also must install [Docker](https://docker.com) at your machine. See the best options [here](https://docs.docker.com/engine/install/ubuntu/).

## Run Container

After everything setup, at the root of the project directory (as root):
```
# Starting docker
$ docker compose up
```
This will set bring up the container. If will want it to run as a daemon add the `-d` option:
```
$ docker compose up -d
```
To bring it down:
```
$ docker compose down
```

## Reference

* [SYSLINUX](https://wiki.syslinux.org/wiki/index.php?title=SYSLINUX)
* [Set up PXE](https://medium.com/jacklee26/set-up-pxe-server-on-ubuntu20-04-and-window-10-e69733c1de87): a good article about setting up PXE server, especially part 3, that describes how to create a Windows PE ISO to boot Windows system.
* [Clonezilla](https://clonezilla.org/livepxe.php)
* [GParted](https://gparted.org/livepxe.php)