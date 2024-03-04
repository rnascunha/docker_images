#!/bin/bash
#################################################################################
# Configure files
# Author Rafael Cunha <rnascunha@gmail.com>
#################################################################################

#################################################################################
# Variables that will be used to configure the files
#################################################################################

# Directory where are the template of the files to configure (don't change this)
template_dir=$(echo $(dirname $0)/../template)
#Source directory
source_dir=$(echo $(dirname $0)/../src)
# Files that will be configured
files=(.env etc/dnsmasq.conf tftpboot/pxelinux.cfg/default tftpboot/pxelinux.cfg/gparted tftpboot/pxelinux.cfg/clonezilla)

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

#################################################################################
# Functions
#################################################################################
. $(dirname $0)/validate.sh

print_all_variables() {
  local variables=(template_dir output_dir images_dir server_ip router_ip dhcp_ini dhcp_end netmask lease_time domain)
  for var in "${variables[@]}"; do 
    echo -e "\t${var}=${!var}"
  done
}

error_msg() {
  echo "ERROR! $1"
}

# Validate if network parameters make sense (are at the same network)
#
# As the parameters where already validated, we will not check the status
# returned
validate_network_parameters() {  
  local snet=$(ipv4_network $server_ip $netmask)
  local rnet=$(ipv4_network $router_ip $netmask)
  local dinet=$(ipv4_network $dhcp_ini $netmask)
  local denet=$(ipv4_network $dhcp_end $netmask)

  if [ $snet != $rnet -o $snet != $rnet -o $snet != $dinet -o $snet != $denet ]; then
    error_msg "Parameters are not at the same network"
    echo "server=$snet / router=$rnet / dhcp=$dinet,$denet"
    exit 10
    return 1
  fi

  return 0
}

# Help function
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

##################################################################################
# Read arguments
##################################################################################

while getopts ":hi:s:r:c:n:l:d:t:o:" o; do
  case "$o" in
    h)
      help
      exit 0
      ;;
    i)
      images_dir=$OPTARG
      ;;
    s)
      server_ip=$OPTARG
      ;;
    r)
      router_ip=$OPTARG
      ;;
    c)
      dhcp_ini=$(cut -d, -f1 -s <<< $OPTARG)
      dhcp_end=$(cut -d, -f2 -s <<< $OPTARG)
      ;;
    n)
      netmask=$OPTARG
      ;;
    l)
      lease_time=$OPTARG
      ;;
    d) 
      domain=$OPTARG
      ;;
    t)
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

#################################################################################
# Validating inputs
#################################################################################

# Output directory
if [ -e "$output_dir" ]; then
  if [ ! -d "$output_dir" ]; then
    error_msg "Output directory '$output_dir' exist and is not a directory"
    exit 8
  fi
  echo "Output directory '$output_dir' already create."
else
  echo "Creating output directory '$output_dir'"
  mkdir -p $output_dir
fi

# Images directory
if [ ! -d "$images_dir" ]; then
  error_msg "'$images_dir' is not a valid directory path"
  exit 2
fi

# Template directory
if [ ! -d "$template_dir" ]; then
  error_msg "'$template_dir' is not a valid directory path"
  exit 7
fi

# Server address
validate_ipv4 $server_ip
if [ $? -ne 0 ]; then
  error_msg "'$server_ip' is not a valid IP address"
  exit 3
fi

# Router address
validate_ipv4 $router_ip
if [ $? -ne 0 ]; then
  error_msg "'$router_ip' is not a valid IP address"
  exit 4
fi

# Netmask
validate_ipv4_netmask $netmask
if [ $? -ne 0 ]; then
  error_msg "'$netmask' is not a valid netmask address"
  exit 6
fi

# DHCP Range
validate_ipv4 $dhcp_ini
if [ $? -ne 0 ]; then
  error_msg "'$dhcp_ini' is not a valid IP address"
  exit 5
fi
validate_ipv4 $dhcp_end
if [ $? -ne 0 ]; then
  error_msg "'$dhcp_end' is not a valid IP address"
  exit 5
fi

validate_network_parameters

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

########################################
# Configure each file
########################################
configure_file() {
  local file_full="$template_dir/$1"
  local output_full="$output_dir/$1"
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

# Copying all files to the output directory
cp -rf $source_dir/. $output_dir

for file in "${files[@]}"; do
  configure_file $file
done
