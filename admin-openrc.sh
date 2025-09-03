#!/bin/bash
# Admin credentials for OpenStack CLI
export OS_PASSWORD=admin123
export OS_PROJECT_NAME=admin
export OS_TENANT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_USER_DOMAIN_ID=default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_ID=default
export OS_AUTH_URL=http://localhost:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_USERNAME=admin
export OS_REGION_NAME=RegionOne

# For debugging
export OS_DEBUG=0

echo "OpenStack admin credentials loaded"
echo "Auth URL: $OS_AUTH_URL"
echo "Username: $OS_USERNAME" 
echo "Project: $OS_PROJECT_NAME"
echo "Region: $OS_REGION_NAME"