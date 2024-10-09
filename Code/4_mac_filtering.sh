#!/bin/bash
# Run script 3_setup.sh
pause() {
    read -p "Press Enter to continue..."
}

echo "======================================"
echo "MAC FILTERING: Allow List"
echo "======================================"


# Reset ebtables to remove existing rules
ebtables -F
# Allow ARP (Address Resolution Protocol) packets
ebtables -A FORWARD -p arp -j ACCEPT
# Allow packets from specific MAC address 'aa:bb:cc:dd:ee:01'
ebtables -A FORWARD -s aa:bb:cc:dd:ee:01 -j ACCEPT
# Drop all other packets by default
ebtables -A FORWARD -j DROP
echo "Allow List rules applied"
ebtables -L
pause


echo "Starting tcpdump on h1 and h2..."
ip netns exec h1 tcpdump -i veth1 icmp -e -n > h1_tcpdump_output.txt 2>&1 &
TCPDUMP_H1_PID=$!
ip netns exec h2 tcpdump -i veth2 icmp -e -n > h2_tcpdump_output.txt 2>&1 &
TCPDUMP_H2_PID=$!

sleep 2 

echo "Executing ping from h1 to h2:"
ip netns exec h1 ping -c 3 192.168.1.2

pause # wait for the ping to end before pressing enter

echo "Stopping tcpdump on h1 and h2..."
kill $TCPDUMP_H1_PID
kill $TCPDUMP_H2_PID

echo "tcpdump output on h1:"
cat h1_tcpdump_output.txt
echo "--------------------------------------"
echo "tcpdump output on h2:"
cat h2_tcpdump_output.txt

pause


echo "Starting tcpdump on h1 and h2..."
ip netns exec h1 tcpdump -i veth1 icmp -c 5 > h1_tcpdump_output.txt 2>&1 &
TCPDUMP_H1_PID=$!
ip netns exec h2 tcpdump -i veth2 icmp -c 5 > h2_tcpdump_output.txt 2>&1 &
TCPDUMP_H2_PID=$!

sleep 2

echo "Executing ping from h2 to h1:"
ip netns exec h2 ping -n -c 3 192.168.1.1

pause

echo "Stopping tcpdump on h1 and h2..."
kill $TCPDUMP_H1_PID
kill $TCPDUMP_H2_PID

echo "tcpdump output on h2:"
cat h2_tcpdump_output.txt
echo "--------------------------------------"
echo "tcpdump output on h1:"
cat h1_tcpdump_output.txt

pause

echo "======================================"
echo "MAC FILTERING: Deny List"
echo "======================================"

# Flush ebtables to clear current rules
ebtables -F
# Drop packets from all MAC addresses except 'aa:bb:cc:dd:ee:02', but only for non-ARP packets
ebtables -A FORWARD -p ! arp -s aa:bb:cc:dd:ee:02 -j DROP
# Allow all other traffic
ebtables -A FORWARD -j ACCEPT
# Display current ebtables rules
ebtables -L
echo "Deny List rules applied."
pause

echo "Starting tcpdump on h1 and h2..."
ip netns exec h1 tcpdump -i veth1 icmp -e -n > h1_tcpdump_output.txt 2>&1 &
TCPDUMP_H1_PID=$!
ip netns exec h2 tcpdump -i veth2 icmp -e -n > h2_tcpdump_output.txt 2>&1 &
TCPDUMP_H2_PID=$!

sleep 1

echo "Executing ping from h2 to h1:"
ip netns exec h2 ping -c 3 192.168.1.1

pause

echo "Stopping tcpdump on h1 and h2..."
kill $TCPDUMP_H1_PID
kill $TCPDUMP_H2_PID

echo "tcpdump output on h2:"
cat h2_tcpdump_output.txt
echo "--------------------------------------"
echo "tcpdump output on h1:"
cat h1_tcpdump_output.txt

pause

echo "Starting tcpdump on h1 and h3..."
ip netns exec h1 tcpdump -i veth1 icmp -c 5 > h1_tcpdump_output.txt 2>&1 &
TCPDUMP_H1_PID=$!
ip netns exec h3 tcpdump -i veth3 icmp -c 5 > h3_tcpdump_output.txt 2>&1 &
TCPDUMP_H3_PID=$!

sleep 1 

echo "Executing ping from h1 to h3 (should succeed):"
ip netns exec h1 ping -c 3 192.168.1.3

pause

echo "Stopping tcpdump on h1 and h3..."
kill $TCPDUMP_H1_PID
kill $TCPDUMP_H3_PID

echo "tcpdump output on h1:"
cat h1_tcpdump_output.txt
echo "--------------------------------------"
echo "tcpdump output on h3:"
cat h3_tcpdump_output.txt

