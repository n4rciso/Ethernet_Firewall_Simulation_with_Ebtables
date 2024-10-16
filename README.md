# Ethernet Firewall Simulation with Ebtables

The aim of this project is to create a laboratory focused on Ethernet firewalls using ebtables, a powerful link-layer packet filtering tool for Linux. It is designed to help students grasp the fundamentals of network security and packet filtering at the data link layer. Through this project, students will explore various practical applications of `ebtables`, learning how to address common network attacks like MAC spoofing, ARP spoofing, and MAC flooding using specific configurations. Additionally, the project covers VLAN tagging techniques and how they can be effectively managed using ebtables.

## Table of Contents

1. **Introduction**
   - Overview of firewall concepts, including general firewalls and Ethernet firewalls.
   - Introduction to ebtables as a tool for implementing Ethernet firewalls at the link layer.

2. **Ebtables: Ethernet Bridge Frame Table Administration**
   - Detailed explanation of how ebtables works, focusing on chains, targets, and tables.
   - Discussion on the installation and primary commands used in ebtables to manage Ethernet traffic.

3. **Virtual Network Configuration**
   - Step-by-step configuration of a virtual network using Linux namespaces and virtual Ethernet pairs.
   - Creation of network bridges and their connection to namespaces to simulate network traffic flow.

4. **MAC Filtering and Spoofing**
   - Techniques for implementing MAC address filtering using ebtables, including:
     - **Allow List**: Permits traffic only from specific MAC addresses, blocking all other traffic.
     - **Deny List**: Blocks traffic from specific MAC addresses while allowing all other traffic.
   - **MAC Spoofing Prevention**:
     - Implemented using **IP-MAC Binding**, which ties specific IP addresses to MAC addresses to ensure that only legitimate devices can communicate on the network, effectively blocking devices attempting to spoof MAC addresses.

5. **ARP Spoofing/Poisoning and Countermeasures using Ebtables**
   - In-depth analysis of ARP (Address Resolution Protocol) and its vulnerabilities.
   - **ARP Spoofing Prevention Techniques**:
     - **Static ARP Entries**: Configuring static IP-to-MAC address associations to prevent unauthorized changes in the ARP table.
     - **Selective ARP Reply Filtering**: Allowing only legitimate ARP replies based on predefined IP-MAC pairs, while blocking spoofed ARP replies using ebtables.
     - **Complete ARP Reply Blocking**: For highly secure setups, blocking all ARP replies from untrusted devices to prevent any form of spoofing.

6. **MAC Flooding Attack and Mitigation with Ebtables**
   - Description of MAC flooding attacks that aim to overwhelm the MAC address table of a switch or bridge.
   - **MAC Flooding Prevention Techniques**:
     - **Rate Limiting with Ebtables**: Limiting the number of packets from a specific source to prevent the attacker from flooding the MAC table, ensuring the switch does not degrade to broadcasting traffic indiscriminately.

7. **VLAN Tagging with Ebtables**
   - Introduction to VLAN (Virtual Local Area Network) concepts for enhanced traffic segmentation.
   - Techniques used for correcting VLAN tagging issues using ebtables, ensuring that packets are correctly tagged and isolated within their designated VLANs, even in the presence of configuration errors.

## Project Files

The project includes several shell scripts, each corresponding to a specific chapter in the documentation. Below is a brief description of each script, all of which can be found in the `Code/` directory:

1. **[3_setup.sh](Code/3_setup.sh)**: This script sets up the virtual network environment, configuring Linux namespaces, virtual Ethernet pairs, and bridges necessary to simulate the network for the experiments.

2. **[3_delete.sh](Code/3_delete.sh)**: Used to clean up the environment by removing all the configurations created during the setup process, including namespaces, bridges, and virtual Ethernet interfaces.

3. **[4_mac_filtering.sh](Code/4_mac_filtering.sh)**: Contains commands to implement MAC filtering using ebtables. It includes both Allow List and Deny List configurations to control which devices can communicate within the network.

4. **[4_mac_spoofing.sh](Code/4_mac_spoofing.sh)**: Demonstrates the process of MAC address spoofing and implements countermeasures using IP-MAC binding techniques to prevent unauthorized devices from impersonating legitimate ones.

5. **[5_arp_spoofing.sh](Code/5_arp_spoofing.sh)**: Focuses on ARP spoofing attacks, showing how to execute them and how to mitigate these attacks using various ebtables rules, such as static ARP entries and selective ARP reply filtering.

6. **[6_mac_flooding.sh](Code/6_mac_flooding.sh)**: Simulates a MAC flooding attack that aims to overwhelm the MAC address table of a switch or bridge, along with techniques to prevent this attack using rate limiting with ebtables.

7. **[7_vlan_tagging.sh](Code/7_vlan_tagging.sh)**: Covers VLAN tagging configurations and how to handle VLAN-based network segmentation issues using ebtables to ensure that traffic is correctly tagged and isolated.
