#!/bin/bash
#################################################################################
# Configure files
# Author Rafael Cunha <rnascunha@gmail.com>
#################################################################################

template_dir=template
output_dir=src/
files=(.env etc/dnsmasq.conf tftpboot/pxelinux.cfg/default tftpboot/pxelinux.cfg/gparted tftpboot/pxelinux.cfg/clonezilla)

#################################################################################
# Variables that will be used to configure the files
#################################################################################

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

##################################################################################
# Read arguments
##################################################################################

print_all_variables() {
  variables=(template_dir output_dir images_dir server_ip router_ip dhcp_ini dhcp_end netmask lease_time domain)
  for var in "${variables[@]}"; do 
    echo "${var}=${!var}"
  done
}

validate_ip() {
  [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
  return $?
}

help() {
  echo -e "$(basename $0) -h|\n" \
  "         [-i <images_dir>]\n"  \
  "         [-s <server_ip>]\n" \
  "         [-r <router_ip>]\n"  \
  "         [-c <dhcp-ini>,<dhcp-end>]\n"  \
  "         [-n <netmask>]\n"  \
  "         [-l <lease_time>]\n"  \
  "         [-d <domain>]\n"  \
  "         [-t <template_dir>]\n"  \
  "         [-o <output_dir>]"
}

while getopts ":hi:s:r:c:n:l:d:t:o:" o; do
  case "$o" in
    h)
      help
      exit 0
      ;;
    i)
      if [ ! -d "$OPTARG" ]; then
        echo "'$OPTARG' is not a valid directory path"
        exit 2
      fi
      images_dir=$OPTARG
      ;;
    s)
      validate_ip $OPTARG
      if [ $? -eq 1 ]; then
        echo "'$OPTARG' is not a valid IP address"
        exit 3
      fi
      server_ip=$OPTARG
      ;;
    r)
      validate_ip $OPTARG
      if [ $? -eq 1 ]; then
        echo "'$OPTARG' is not a valid IP address"
        exit 4
      fi
      router_ip=$OPTARG
      ;;
    c)
      dhcp_ini=$(cut -d, -f1 -s <<< $OPTARG)
      validate_ip $dhcp_ini
      if [ $? -eq 1 ]; then
        echo "'$dhcp_ini' is not a valid IP address"
        exit 5
      fi
      dhcp_end=$(cut -d, -f2 -s <<< $OPTARG)
      validate_ip $dhcp_end
      if [ $? -eq 1 ]; then
        echo "'$dhcp_end' is not a valid IP address"
        exit 5
      fi
      ;;
    n)
      validate_ip $OPTARG
      if [ $? -eq 1 ]; then
        echo "'$OPTARG' is not a valid netmask address"
        exit 6
      fi
      netmask=$OPTARG
      ;;
    l)
      lease_time=$OPTARG
      ;;
    d) 
      domain=$OPTARG
      ;;
    t)
      if [ ! -d "$OPTARG" ]; then
        echo "'$OPTARG' is not a valid directory path"
        exit 7
      fi
      template_dir=$OPTARG
      ;;
    o)
      output_dir=$OPTARG
      ;;
    \?)
      echo -e "-- Invalid option: -$OPTARG" >&2
      help
      exit 9
      ;;
    :)
      echo -e "-- No argument provided: -$OPTARG" >&2
      help
      exit 10
      ;;
  esac
done

if [ -e "$output_dir" ]; then
  if [ ! -d "$output_dir" ]; then
    echo "!!! ERROR! Output directory '$output_dir' exist and is not a directory"
    echo "!!! Exiting..."
    exit 8
  fi
  echo "Output directory '$output_dir' already create."
else
  echo "Creating output directory '$output_dir'"
  mkdir -p $output_dir
fi

echo "Configuring files with variables:"
print_all_variables

##################################################################################
# Creating sed command
##################################################################################
variables=(images_dir server_ip router_ip dhcp_ini dhcp_end netmask lease_time domain)
cmd=""
for var in "${variables[@]}"; do 
  cmd="$cmd;s@{{${var^^}}}@${!var}@g"
done

#########################################
# Checking and creating output directory
#########################################


########################################
# Configure each file
########################################
configure_file() {
  file_full="$template_dir/$1"
  output_full="$output_dir/$1"
  if [ ! -f "$file_full" ]; then
    echo "!!! '$file_full' file not found"
    return
  fi
  echo "Configuring '$file'..."
  mkdir -p $(dirname $output_full)
  sed -e $cmd $file_full > $output_full
}

########################################
# Main loop
########################################
for file in "${files[@]}"; do
  configure_file $file
done
