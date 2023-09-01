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
#
# This also allows packets to the Docker network
iptables --insert OUTPUT \
    ! --out-interface "$interface" \
    --match mark ! --mark "$(wg show "$interface" fwmark)" \
    --match addrtype ! --dst-type LOCAL \
    ! --destination "$(ip -4 -oneline addr show dev eth0 | awk 'NR == 1 { print $4 }')" \
    --jump REJECT

# nft insert rule ip filter OUTPUT \
#     oifname != "$interface" \
#     mark != "$(wg show "$interface" fwmark)" \
#     fib daddr type != local \
#     ip daddr != "$(ip -4 -oneline addr show dev eth0 | awk 'NR == 1 { print $4 }')" \
#     counter reject


# Create static routes for any ALLOWED_SUBNETS and punch holes in the firewall
default_gateway=$(ip -4 route | awk '$1 == "default" { print $3 }')
for subnet in ${ALLOWED_SUBNETS//,/ }; do
    ip route add "$subnet" via "$default_gateway"
    iptables --insert OUTPUT \
        --destination "$subnet" \
        --jump ACCEPT

    # nft insert rule ip filter OUTPUT \
    #     ip daddr "$subnet" \
    #     counter accept
done

sleep infinity &
wait
