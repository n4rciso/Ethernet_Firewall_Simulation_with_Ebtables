#!/bin/bash

# Delete veth pairs and bridges
ip link delete veth1 2>/dev/null
ip link delete veth2 2>/dev/null
ip link delete veth3 2>/dev/null
ip link delete fw-v1 2>/dev/null
ip link delete sw-v1 2>/dev/null
ip link delete sw-v2 2>/dev/null
ip link delete fw-sw 2>/dev/null
ip link delete sw-fw 2>/dev/null
ip link delete br-fw type bridge 2>/dev/null
ip link delete br-sw type bridge 2>/dev/null

# Delete namespaces
ip netns delete h1 2>/dev/null
ip netns delete h2 2>/dev/null
ip netns delete h3 2>/dev/null

echo "Network configuration cleaned up."

