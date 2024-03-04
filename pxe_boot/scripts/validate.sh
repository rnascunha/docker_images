#!/bin/bash
##################################################################
# A set o bash function to validade/calculate network parameters
#
# Author: Rafael Cunha <rnascunha@gmail.com>
# Date: 10/02/2024
##################################################################

#######################################################
# Auxiliary functions
#######################################################
binary_to_number() {
  echo -n $((2#$1))
}

number_to_binary() {
  echo "obase=2; ibase=10; $1" | bc
}

number_to_ipv4() {
  echo -n $(binary_to_ipv4 $(number_to_binary $1))
}

ipv4_to_binary() {
  echo "obase=2; ibase=10; ${1//./;}" | bc | xargs -I'{}' printf "%08d" '{}'
}

binary_to_ipv4() {
  echo -n "$((2#${1:0:8})).$((2#${1:8:8})).$((2#${1:16:8})).$((2#${1:24:8}))"
}

#######################################################
# Validate if argument is a valid IPv4
# Call: validate_ipv4 <ip>
# Return status: 0: valid, 1: invalid
#######################################################
validate_ipv4() {
  [[ $1 =~ ^((0|[1-9]{1}|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}(0|[1-9]{1}|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]
}

#######################################################
# Validate if argument is a valid MAC address
# Call: validate_mac <mac>
# Return status: 0: valid, 1: invalid
#######################################################
validate_mac() {
  [[ $1 =~ ^([0-9a-fA-F]{2}\:){5}[0-9a-fA-F]{2}$ ]]
}

#######################################################
# Validate if argument is a valid IPv4 netmask
# Call: validate_ipv4_netmask <netmask>
# Return status: 0: valid, 1: invalid
#
# See: https://stackoverflow.com/a/21746988
#######################################################
validate_ipv4_netmask() {
  [[ $1 =~ ^(254|252|248|240|224|192|128)\.0\.0\.0|255\.(254|252|248|240|224|192|128|0)\.0\.0|255\.255\.(254|252|248|240|224|192|128|0)\.0|255\.255\.255\.(254|252|248|240|224|192|128|0)$ ]]
}

#######################################################
# Validate if argument is a valid CIDR 
# Call: validate_cidr <cidr>
# Return status: 0: valid, 1: invalid
#######################################################
validate_cidr() {
  if [ "$1" -lt 1 -o "$1" -gt 31 ]; then
    return 1
  fi
  return 0
}

#######################################################
# Convert IPv4 netmask to number
# Call: convert_netmask_to_number <netmask>
# Return: Network CIDR
# Return status: 0: success, 1: error
#######################################################
convert_netmask_to_cidr() {
  validate_ipv4_netmask $1
  if [ $? -ne 0 ]; then
    return 1
  fi

  local binary=$(ipv4_to_binary $1)
  local r=${binary//0/}

  echo -n ${#r}
  return 0
}

#######################################################
# Convert CIDR to netmask
# Call: convert_cidr_to_netmask <cidr>
# Return: Network netwask
# Return status: 0: success, 1: error
#
# See: https://gist.github.com/kwilczynski/5d37e1cced7e76c7c9ccfdf875ba6c5b
#######################################################
convert_cidr_to_netmask() {
  validate_cidr $1
  if [ $? -ne 0 ]; then
    return 1
  fi

  local value=$(( 0xffffffff ^ ((1 << (32 - $1)) - 1) ))
  echo -n $(number_to_ipv4 $value)
  
  return 0
}

#######################################################
# Calculate the prefix of a network
#
# This funtion returns a number that represents the network
# prefix.
#
# Call: network_ipv4_prefix <ipv4> <netmask>
# Return: Network prefix number
# Return status: 0: success, 1: error
#######################################################
network_ipv4_prefix() {
  validate_ipv4 $1
  if [ $? -ne 0 ]; then
    return 1
  fi

  validate_ipv4_netmask $2
  if [ $? -ne 0 ]; then
    return 2
  fi

  local ipb=$(ipv4_to_binary $1)
  local netmaskb=$(ipv4_to_binary $2)

  echo -n $((2#$ipb & 2#$netmaskb))
  return 0
}

#######################################################
# Calculate the broadcast suffix of a network
#
# This funtion returns a number that represents all the
# bits that must be set to make the network of the netmask
# provided to a broadcast address
#
# Call: broadcast_ipv4_suffix <netmask>
# Return: Network broadcast suffix number
# Return status: 0: success, 1: error
#######################################################
broadcast_ipv4_suffix() {
  validate_ipv4_netmask $1
  if [ $? -ne 0 ]; then
    return 1
  fi

  local net_num=$(ipv4_to_binary $1)

  echo -n $((0xffffffff & ~(2#$net_num)))
  return 0
}

#######################################################
# Calculate the ipv4 of a network preffix
#
# Call: ipv4_network <ipv4> <netmask>
# Return: Network ipv4 suffix
# Return status: 0: success, 1: error
#######################################################
ipv4_network() {
  local prefix=$(network_ipv4_prefix $1 $2)
  if [ $? -ne 0 ]; then
    return $?
  fi

  echo -n $(number_to_ipv4 $prefix)
  return 0
}

#######################################################
# Calculate the broadcast ipv4 of a network
#
# Call: broadcast_ipv4_suffix <ipv4> <netmask>
# Return: Network ipv4 broadcast address
# Return status: 0: success, 1: error
#######################################################
ipv4_broadcast() {
  local prefix=$(network_ipv4_prefix $1 $2)
  if [ $? -ne 0 ]; then
    return $?
  fi

  local broad=$(broadcast_ipv4_suffix $2)

  echo -n $(number_to_ipv4 $(($prefix | $broad)))
  return 0
}
