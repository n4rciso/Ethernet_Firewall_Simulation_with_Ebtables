#!/bin/bash
echo "Network setup and pings started."

# Create namespaces for host1, host2, and host3
ip netns add h1
ip netns add h2
ip netns add h3

# Create veth pairs
ip link add veth1 type veth peer name fw-v1
ip link add veth2 type veth peer name sw-v1
ip link add veth3 type veth peer name sw-v2

# Create the firewall bridge (br-fw)
ip link add name br-fw type bridge

# Create the switch bridge (br-sw)
ip link add name br-sw type bridge

# Connect veth1 to h1 and fw-v1 to br-fw
ip link set veth1 netns h1
ip link set fw-v1 master br-fw

# Connect veth2 to h2 and sw-v1 to br-sw
ip link set veth2 netns h2
ip link set sw-v1 master br-sw

# Connect veth3 to h3 and sw-v2 to br-sw
ip link set veth3 netns h3
ip link set sw-v2 master br-sw

# Connect the two bridges (firewall and switch) together
ip link add fw-sw type veth peer name sw-fw
ip link set fw-sw master br-fw
ip link set sw-fw master br-sw

# Set all interfaces on the bridges up
ip link set fw-v1 up
ip link set sw-v1 up
ip link set sw-v2 up
ip link set fw-sw up
ip link set sw-fw up
ip link set br-fw up
ip link set br-sw up

# Configure loopback and veth interfaces, assign IPs and MACs for h1, h2, and h3

# h1 configuration
ip netns exec h1 ip link set lo up
ip netns exec h1 ip link set dev veth1 address aa:bb:cc:dd:ee:01
ip netns exec h1 ip link set veth1 up
ip netns exec h1 ip addr add 192.168.1.1/24 dev veth1

# h2 configuration
ip netns exec h2 ip link set lo up
ip netns exec h2 ip link set dev veth2 address aa:bb:cc:dd:ee:02
ip netns exec h2 ip link set veth2 up
ip netns exec h2 ip addr add 192.168.1.2/24 dev veth2

# h3 configuration
ip netns exec h3 ip link set lo up
ip netns exec h3 ip link set dev veth3 address aa:bb:cc:dd:ee:03
ip netns exec h3 ip link set veth3 up
ip netns exec h3 ip addr add 192.168.1.3/24 dev veth3

# Test connectivity with ping

echo "Pinging from h1 (192.168.1.1) to h2 (192.168.1.2)..."
ip netns exec h1 ping -c 3 192.168.1.2

echo "Pinging from h1 (192.168.1.1) to h3 (192.168.1.3)..."
ip netns exec h1 ping -c 3 192.168.1.3

echo "Pinging from h2 (192.168.1.2) to h3 (192.168.1.3)..."
ip netns exec h2 ping -c 3 192.168.1.3

echo "Pinging from h3 (192.168.1.3) to h1 (192.168.1.1)..."
ip netns exec h3 ping -c 3 192.168.1.1

# End of script
echo "Network setup and pings completed."

