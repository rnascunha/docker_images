#!/bin/bash

image_name=pxelinux:test

# sudo docker image rm $image_name
# sudo docker build --tag $image_name --file ubuntu.Dockerfile . && \
#   sudo docker run --rm -it --cap-add=NET_ADMIN --privileged --network host \
#                   -v "$HOME"/data/images:/tftpboot/images \
#                   --name pxelinux $image_name


sudo docker image rm $image_name
sudo docker volume rm nfsimages
sudo docker volume create --driver local \
                  --opt type=nfs \
                  --opt o="addr=192.168.0.3,rw" \
                  --opt device=:/home/rnascunha/data/images/ubuntu \
                  nfsimages
sudo docker build --tag $image_name --file Dockerfile . && \
  sudo docker run --rm -it --privileged --network host \
                  -v "$HOME"/data/images:/tftpboot/images \
                  -v nfsimages:/tftpboot/images/ubuntu  \
                  --name pxelinux $image_name
