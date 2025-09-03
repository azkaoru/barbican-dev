#!/bin/bash

# Key-Manager (Barbican) Endpoint Creation Demo
# This script demonstrates how to create VIP endpoints for the key-manager service

set -e

echo "=== Key-Manager (Barbican) Endpoint Creation Demo ==="
echo ""

# Source admin credentials
echo "Loading admin credentials..."
source ./admin-openrc.sh
echo ""

# Check if we can connect to keystone (this will fail in demo since keystone isn't running)
echo "Checking Keystone connectivity..."
echo "NOTE: This would normally test 'openstack token issue' but will fail without running keystone"
echo ""

# Show the service creation command
echo "=== Step 1: Create Key-Manager Service ==="
echo "Command to create the key-manager service:"
echo "openstack service create --name barbican --description \"OpenStack Key Management Service\" key-manager"
echo ""

# Show endpoint creation commands for VIP
echo "=== Step 2: Create Key-Manager Endpoints ==="
echo "Commands to create VIP endpoints for key-manager service:"
echo ""

# Example VIP IP (this would be your actual VIP IP)
VIP_IP="192.168.1.100"  # Replace with actual VIP IP
PORT="9311"            # Default Barbican port

echo "1. Create PUBLIC endpoint:"
echo "openstack endpoint create --region RegionOne key-manager public http://${VIP_IP}:${PORT}"
echo ""

echo "2. Create INTERNAL endpoint:"
echo "openstack endpoint create --region RegionOne key-manager internal http://${VIP_IP}:${PORT}"
echo ""

echo "3. Create ADMIN endpoint:"
echo "openstack endpoint create --region RegionOne key-manager admin http://${VIP_IP}:${PORT}"
echo ""

echo "=== Alternative: Single command for all interfaces ==="
echo "You can also use localhost for testing:"
echo "openstack endpoint create --region RegionOne key-manager public http://localhost:9311"
echo "openstack endpoint create --region RegionOne key-manager internal http://localhost:9311"
echo "openstack endpoint create --region RegionOne key-manager admin http://localhost:9311"
echo ""

echo "=== Step 3: Verify Endpoints ==="
echo "Command to list all endpoints:"
echo "openstack endpoint list --service key-manager"
echo ""

echo "=== Step 4: Test Key-Manager Service ==="
echo "Commands to test the key-manager service:"
echo "openstack secret store --name 'test-secret' --payload 'my-secret-data'"
echo "openstack secret list"
echo ""

echo "=== Prerequisites ==="
echo "Before running these commands, ensure:"
echo "1. Keystone service is running and accessible"
echo "2. Barbican (key-manager) service is running on the VIP"
echo "3. VIP is properly configured and accessible"
echo "4. Admin credentials are properly configured"
echo ""

echo "Demo completed. The endpoints can be created once Keystone is running."