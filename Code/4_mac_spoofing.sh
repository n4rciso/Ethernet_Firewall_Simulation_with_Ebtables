#!/bin/bash
pause() {
    # Function to pause execution and wait for user input
    read -p "Press Enter to continue..."
}

echo "======================================"
echo "Setting up initial ebtables rules (Allow List)"
echo "======================================"

# Clear existing ebtables rules
ebtables -F

# Allow ARP packets to pass through
ebtables -A FORWARD -p arp -j ACCEPT

# Allow packets from h1's MAC address
ebtables -A FORWARD -s aa:bb:cc:dd:ee:01 -j ACCEPT

# Drop all other packets
ebtables -A FORWARD -j DROP

echo "Initial ebtables rules applied."
ebtables -L

pause

echo "======================================"
echo "Testing connectivity from h2 to h3 before spoofing (should fail)"
echo "======================================"

# Start tcpdump on h3 to capture ICMP packets
echo "Starting tcpdump on h3..."
ip netns exec h3 tcpdump -i veth3 icmp -n -e -c 5 > h3_tcpdump_before_spoof.txt 2>&1 &
TCPDUMP_H3_PID=$!

# Give tcpdump a moment to start
sleep 1

# Attempt to ping h3 from h2 (expected to fail due to ebtables rules)
ip netns exec h2 ping -c 3 192.168.1.3

# Wait for tcpdump to capture packets
sleep 2

# Stop tcpdump
kill $TCPDUMP_H3_PID

# Display tcpdump output
echo "tcpdump output on h3 before spoofing (should be empty or show no packets from h2):"
cat h3_tcpdump_before_spoof.txt

pause

echo "======================================"
echo "Spoofing MAC address of h2 to match h1"
echo "======================================"

# Install macchanger if not already installed
if ! command -v macchanger &> /dev/null; then
    echo "Installing macchanger..."
    sudo apt-get update
    sudo apt-get install -y macchanger
fi

# Change h2's MAC address to match h1's MAC address
ip netns exec h2 macchanger --mac=aa:bb:cc:dd:ee:01 veth2

# Verify the MAC address change
echo "h2's MAC address after spoofing:"
ip netns exec h2 ip link show veth2 | grep ether

pause

echo "======================================"
echo "Testing connectivity from h2 to h3 after spoofing (should succeed)"
echo "======================================"

# Start tcpdump on h3 to capture ICMP packets
echo "Starting tcpdump on h3..."
ip netns exec h3 tcpdump -i veth3 icmp -n -e -c 5 > h3_tcpdump_after_spoof.txt 2>&1 &
TCPDUMP_H3_PID=$!

# Give tcpdump a moment to start
sleep 1

# Attempt to ping h3 from h2
ip netns exec h2 ping -c 3 192.168.1.3

# Wait for tcpdump to capture packets
sleep 2

# Stop tcpdump
kill $TCPDUMP_H3_PID

# Display tcpdump output
echo "tcpdump output on h3 after spoofing (should show ICMP packets from h2):"
cat h3_tcpdump_after_spoof.txt

pause

echo "======================================"
echo "Restoring h2's original MAC address"
echo "======================================"

# Restore h2's original MAC address
ip netns exec h2 macchanger --mac=aa:bb:cc:dd:ee:02 veth2

# Verify the MAC address restoration
echo "h2's MAC address after restoration:"
ip netns exec h2 ip link show veth2 | grep ether

pause

echo "======================================"
echo "Setting up IP-MAC Binding with ebtables"
echo "======================================"

# Clear existing ebtables rules
ebtables -F

# Allow ARP packets
ebtables -A FORWARD -p arp -j ACCEPT

# IP-MAC binding rules
# Allow traffic from h1 (IP: 192.168.1.1, MAC: aa:bb:cc:dd:ee:01)
ebtables -A FORWARD -p IPv4 --ip-source 192.168.1.1 -s aa:bb:cc:dd:ee:01 -j ACCEPT

# Allow traffic from h2 (IP: 192.168.1.2, MAC: aa:bb:cc:dd:ee:02)
ebtables -A FORWARD -p IPv4 --ip-source 192.168.1.2 -s aa:bb:cc:dd:ee:02 -j ACCEPT

# Allow traffic from h3 (IP: 192.168.1.3, MAC: aa:bb:cc:dd:ee:03)
ebtables -A FORWARD -p IPv4 --ip-source 192.168.1.3 -s aa:bb:cc:dd:ee:03 -j ACCEPT

# Drop all other IPv4 packets
ebtables -A FORWARD -p IPv4 -j DROP

echo "IP-MAC binding rules applied."
ebtables -L

# Clear the ARP cache on all namespaces
ip netns exec h1 ip neigh flush all
ip netns exec h2 ip neigh flush all
ip netns exec h3 ip neigh flush all

pause

echo "======================================"
echo "Testing valid communication from h1 to h2 (should succeed)"
echo "======================================"

# Start tcpdump on h2 to capture ICMP packets from h1
echo "Starting tcpdump on h2..."
ip netns exec h2 tcpdump -i veth2 icmp -n -e -c 5 > h2_tcpdump_valid_comm.txt 2>&1 &
TCPDUMP_H2_PID=$!

# Give tcpdump a moment to start
sleep 1

# Ping h2 from h1 (should succeed)
ip netns exec h1 ping -c 3 192.168.1.2

# Wait for tcpdump to capture packets
sleep 2

# Stop tcpdump
kill $TCPDUMP_H2_PID

# Display tcpdump output
echo "tcpdump output on h2 during valid communication from h1:"
cat h2_tcpdump_valid_comm.txt

pause

echo "======================================"
echo "Attempting MAC spoofing on h2 and testing communication (should fail)"
echo "======================================"

# Spoof h2's MAC address to h1's MAC address
ip netns exec h2 macchanger --mac=aa:bb:cc:dd:ee:01 veth2

# Verify the MAC address change
echo "h2's MAC address after spoofing to h1's MAC:"
ip netns exec h2 ip link show veth2 | grep ether

# Start tcpdump on h3 to capture ICMP packets
echo "Starting tcpdump on h3..."
ip netns exec h3 tcpdump -i veth3 icmp -n -e -c 5 > h3_tcpdump_spoof_attempt.txt 2>&1 &
TCPDUMP_H3_PID=$!

# Give tcpdump a moment to start
sleep 1

# Attempt to ping h3 from h2 (should fail due to IP-MAC binding)
ip netns exec h2 ping -c 3 192.168.1.3

# Wait for tcpdump to capture packets
sleep 2

# Stop tcpdump
kill $TCPDUMP_H3_PID

# Display tcpdump output
echo "tcpdump output on h3 after spoofing during IP-MAC binding (should show no packets):"
cat h3_tcpdump_spoof_attempt.txt

pause

echo "======================================"
echo "Restoring h2's original MAC address after failed spoofing attempt"
echo "======================================"

# Restore h2's original MAC address
ip netns exec h2 macchanger --mac=aa:bb:cc:dd:ee:02 veth2

# Verify the MAC address restoration
echo "h2's MAC address after restoration:"
ip netns exec h2 ip link show veth2 | grep ether

echo "Script execution completed."

