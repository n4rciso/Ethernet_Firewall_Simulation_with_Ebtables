#!/bin/bash
ebtables -t broute -F
echo "Starting MAC flooding attack from h1..."
sleep 3
ip netns exec h1 macof -i veth1 &
MACOF_PID=$! 
sleep 1
echo "Killing the MAC flooding attack process..."
kill $MACOF_PID
echo "Checking the MAC table on the bridge (br-fw) after flooding..."
sleep 2
bridge fdb show dev fw-v1
sleep 5

echo "Flushing the MAC table by resetting the bridge interface..."
ip link set dev fw-v1 down
ip link set dev fw-v1 up

echo "Applying ebtables rules to mitigate MAC flooding..."
# Rule to accept a limited number of packets per minute with an initial burst
ebtables -t broute -A BROUTING -i fw-v1 --limit 7/s --limit-burst 3 -j ACCEPT

# Drops all packets exceeding the limit
ebtables -t broute -A BROUTING -i fw-v1 -j DROP

ebtables -t broute -L

echo "Ebtables rules applied. MAC flooding attack should now be mitigated."

sleep 3
# Demonstration of Attack Blocking
echo "Restarting the MAC flooding attack from h1..."
ip netns exec h1 macof -i veth1 &
MACOF_PID=$! 
sleep 1
echo "Killing the MAC flooding attack process..."
kill $MACOF_PID
echo "Checking the MAC table on the bridge (br-fw) after applying the ebtables rules..."
sleep 2
bridge fdb show dev fw-v1



