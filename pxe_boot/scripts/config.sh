#!/bin/bash
#################################################################################
# Create configuration files
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
# Fixed IPs array
fixed_ips=()

#################################################################################
# Functions
#################################################################################
. $(dirname $0)/validate.sh

print_all_variables() {
  local variables=(template_dir output_dir images_dir server_ip router_ip dhcp_ini dhcp_end netmask lease_time domain)
  for var in "${variables[@]}"; do 
    echo -e "\t${var}=${!var}"
  done
  echo -e "\tfixed_ips=$(echo ${fixed_ips[@]})"
}

error_msg() {
  echo "ERROR! $1"
}

check_ip() {
  validate_ipv4 $1
  if [ $? -ne 0 ]; then
    error_msg "$1 is not a valid IP address"
    exit $2
  fi
}

# Validate if network parameters make sense (are at the same network)
#
# As the parameters where already validated, we will not check the status
# returned
validate_network_parameters() {  
  local snet=$(ipv4_network $server_ip $netmask)
  local array_ip=($(ipv4_network $router_ip $netmask)
                  $(ipv4_network $router_ip $netmask)
                  $(ipv4_network $dhcp_ini $netmask)
                  $(ipv4_network $dhcp_end $netmask))

  for hwip in ${fixed_ips[@]}; do 
    local hw=$(cut -d, -f1 <<< $hwip)
    local ip=$(cut -d, -f$(wc -c <<< ${hwip//[^,]}) <<< $hwip) 
    validate_mac $hw
    if [ $? -ne 0 ]; then
      error_msg "'$hw' is not a valid MAC address"
      exit 11
    fi
    check_ip $ip 12
    array_ip+=($(ipv4_network $ip $netmask))
  done

  for ipnet in ${array_ip[@]}; do
    if [ $snet != $ipnet ]; then
      error_msg "Parameters are not at the same network"
      echo "server=$snet / ip=$ipnet"
      exit 13
    fi
  done

  return 0
}

# Help function
help() {
  echo -e "$(basename $0) -h|
          [-i <images_dir>]
          [-s <server_ip>]
          [-r <router_ip>]
          [-c <dhcp-ini>,<dhcp-end>]
          [-n <netmask>]
          [-l <lease_time>]
          [-d <domain>]
          [-o <output_dir>]
          [-f <hw_addr>[,<host_name>],<fixed_ip>]"
}

##################################################################################
# Read arguments
##################################################################################

while getopts ":hi:s:r:c:n:l:d:t:o:f:" o; do
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
    f)
      fixed_ips+=($OPTARG)
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
check_ip $server_ip 3
# Router address
check_ip $router_ip 4
# DHCP Range
check_ip $dhcp_ini 5
check_ip $dhcp_end 5

# Netmask
validate_ipv4_netmask $netmask
if [ $? -ne 0 ]; then
  error_msg "'$netmask' is not a valid netmask address"
  exit 6
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

add_fixed_host() {
  echo "dhcp-host=$1,infinite" >> "$output_dir/etc/dnsmasq.conf"
}

########################################
# Main loop
########################################

# Copying all files to the output directory
cp -rf $source_dir/. $output_dir

# Configuring template files
for file in "${files[@]}"; do
  configure_file $file
done

# Adding fixed hosts IPs
for fip in ${fixed_ips[@]}; do
  add_fixed_host $fip
done
