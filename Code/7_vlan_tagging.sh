#!/bin/bash

# Clean up any previous environment
echo "Cleaning up previous environment..."
ip netns del h1 2>/dev/null
ip netns del h2 2>/dev/null
ip netns del h3 2>/dev/null
ip link del veth1 2>/dev/null
ip link del veth2 2>/dev/null
ip link del veth3 2>/dev/null
ip link del br0 2>/dev/null

# Create namespaces
echo "Creating namespaces..."
ip netns add h1
ip netns add h2
ip netns add h3

# Create virtual Ethernet interfaces (veth)
echo "Creating virtual Ethernet interfaces..."
ip link add veth1 type veth peer name veth1-br
ip link add veth2 type veth peer name veth2-br
ip link add veth3 type veth peer name veth3-br

# Attach the interfaces to namespaces
echo "Attaching interfaces to namespaces..."
ip link set veth1 netns h1
ip link set veth2 netns h2
ip link set veth3 netns h3

# Create a bridge
echo "Creating the bridge..."
ip link add name br0 type bridge
ip link set br0 up

# Attach the interfaces to the bridge
echo "Attaching interfaces to the bridge..."
ip link set veth1-br master br0
ip link set veth2-br master br0
ip link set veth3-br master br0

# Activate the interfaces
echo "Activating interfaces..."
ip link set veth1-br up
ip link set veth2-br up
ip link set veth3-br up

# Configure VLAN interfaces in the namespaces (all with VLAN 100)
echo "Configuring VLAN interfaces (VLAN 100) in namespaces..."

# h1
ip netns exec h1 ip link add link veth1 name veth1.100 type vlan id 100
ip netns exec h1 ip addr add 192.168.1.1/24 dev veth1.100
ip netns exec h1 ip link set veth1 up
ip netns exec h1 ip link set veth1.100 up

# h2
ip netns exec h2 ip link add link veth2 name veth2.100 type vlan id 100
ip netns exec h2 ip addr add 192.168.1.2/24 dev veth2.100
ip netns exec h2 ip link set veth2 up
ip netns exec h2 ip link set veth2.100 up

# h3
ip netns exec h3 ip link add link veth3 name veth3.100 type vlan id 100
ip netns exec h3 ip addr add 192.168.1.3/24 dev veth3.100
ip netns exec h3 ip link set veth3 up
ip netns exec h3 ip link set veth3.100 up

# Test: ping between namespaces before applying ebtables
echo "Testing connectivity before applying ebtables rules..."

# Ping between h1 and h2
echo "Ping from h1 (192.168.1.1) to h2 (192.168.1.2):"
ip netns exec h1 ping -c 3 192.168.1.2
# Ping between h1 and h3
echo "Ping from h1 (192.168.1.1) to h3 (192.168.1.3):"
ip netns exec h1 ping -c 3 192.168.1.3
# Ping between h2 and h3
echo "Ping from h2 (192.168.1.2) to h3 (192.168.1.3):"
ip netns exec h2 ping -c 3 192.168.1.3
echo "=========================================================================="


# Apply ebtables rules to fix the VLAN issue
echo "Applying ebtables rules to simulate VLAN separation..."

# Clear existing ebtables rules
ebtables -t broute -F

# Add a rule to accept packets with VLAN 100 on ns1 and ns2
ebtables -t broute -A BROUTING -i veth1-br -p 802_1Q --vlan-id 100 -j ACCEPT
ebtables -t broute -A BROUTING -i veth2-br -p 802_1Q --vlan-id 100 -j ACCEPT

# Accept VLAN 200 packets for ns3 (simulate it's in VLAN 200)
ebtables -t broute -A BROUTING -i veth3-br -p 802_1Q --vlan-id 200 -j ACCEPT

# Block all traffic not in VLAN 100 or 200 as appropriate
ebtables -t broute -A BROUTING -i veth1-br -j DROP
ebtables -t broute -A BROUTING -i veth2-br -j DROP
ebtables -t broute -A BROUTING -i veth3-br -j DROP
ebtables -t broute -L

# Test: ping after applying ebtables rules
echo "Testing connectivity after applying ebtables rules..."
# Ping between h1 and h2
echo "Ping from h1 (192.168.1.1) to h2 (192.168.1.2):"
ip netns exec h1 ping -c 3 192.168.1.2
# Ping between h1 and h3
echo "Ping from h1 (192.168.1.1) to h3 (192.168.1.3):"
ip netns exec h1 ping -c 3 192.168.1.3
# Ping between h2 and h3
echo "Ping from h2 (192.168.1.2) to h3 (192.168.1.3):"
ip netns exec h2 ping -c 3 192.168.1.3
echo "=========================================================================="

# Cleanup script
echo "Cleaning up the environment..."
ebtables -t broute -F
ip netns del h1 2>/dev/null
ip netns del h2 2>/dev/null
ip netns del h3 2>/dev/null
ip link del veth1 2>/dev/null
ip link del veth2 2>/dev/null
ip link del veth3 2>/dev/null
ip link del br0 2>/dev/null

echo "Cleanup completed."

