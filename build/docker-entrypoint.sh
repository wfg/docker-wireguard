#!/usr/bin/env bash

set -e

cleanup() {
    wg-quick down "$1"
    exit 0
}

# Find a config file and isolate the interface name
config_file=$(find /etc/wireguard -type f -name '*.conf' | shuf -n 1)
if [[ -z $config_file ]]; then
    echo "config file not found"
    exit 1
fi
interface=$(basename "${config_file%.*}")

# Bring up the WireGuard interface
wg-quick up "$interface"

# Gracefully exit when signalled
trap 'cleanup $interface' SIGINT SIGTERM

# > ...when used with interfaces that have a peer that specifies 0.0.0.0/0 as part of the ‘AllowedIPs’,
# > [this iptables command] works together with wg-quick’s fwmark usage in order to drop all packets
# > that are either not coming out of the tunnel encrypted or not going through the tunnel itself
# Source: https://git.zx2c4.com/wireguard-tools/about/src/man/wg-quick.8
iptables --new-chain LOCAL_DOCKER_OUTPUT
iptables --insert OUTPUT \
    ! --out-interface "$interface" \
    --match mark ! --mark "$(wg show "$interface" fwmark)" \
    --match addrtype ! --dst-type LOCAL \
    --jump LOCAL_DOCKER_OUTPUT

# When your container is in multiple networks, you will have multiple interfaces.
# The following lines create a string of all relevant addresses to allow.
local_docker_nets=()
for ifname in $(ip -4 -json link show type veth | jq --raw-output '.[].ifname'); do
    for net in $(ip -4 -json address show dev "$ifname" | jq --raw-output '.[].addr_info[] | "\(.local)/\(.prefixlen)"'); do
        local_docker_nets+=( "$net" )
    done
done
printf -v dest_nets '%s,' "${local_docker_nets[@]}"

iptables --append LOCAL_DOCKER_OUTPUT \
    --destination "${dest_nets%,}" \
    --jump ACCEPT
iptables --append LOCAL_DOCKER_OUTPUT \
    --jump REJECT

# Create static routes for any ALLOWED_SUBNETS and punch holes in the firewall
default_gateway=$(ip -4 -json route | jq --raw-output '.[] | select(.dst == "default") | .gateway')
for subnet in ${ALLOWED_SUBNETS//,/ }; do
    ip route add "$subnet" via "$default_gateway"
    iptables --insert OUTPUT \
        --destination "$subnet" \
        --jump ACCEPT
done

sleep infinity &
wait
