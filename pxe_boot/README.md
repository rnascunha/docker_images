# PXE server

Implementation of a docker container that will handle all the

```
# Build image
$ sudo docker build -t pxelinux:test

# Run image
$ sudo docker run --rm -it --cap-add=NET_ADMIN --network host --name pxelinux pxelinux:test
```

## Reference

* https://wiki.syslinux.org/wiki/index.php?title=SYSLINUX
* https://medium.com/jacklee26/set-up-pxe-server-on-ubuntu20-04-and-window-10-e69733c1de87
* https://clonezilla.org/livepxe.php
* https://gparted.org/livepxe.php