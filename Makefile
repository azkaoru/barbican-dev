# Barbican Development Environment Makefile
# This Makefile provides convenient targets for managing the podman-compose services

.PHONY: help postgres keystone barbican clean clean-postgres clean-keystone clean-barbican build-base

# Default target
help:
	@echo "Barbican Development Environment"
	@echo "================================"
	@echo ""
	@echo "Available targets:"
	@echo "  build-base       Build the base container image"
	@echo "  postgres         Start PostgreSQL service"
	@echo "  keystone         Start Keystone service"
	@echo "  barbican         Start Barbican service"
	@echo "  clean            Stop and remove all services with volumes"
	@echo "  clean-postgres   Stop and remove PostgreSQL service with volumes"
	@echo "  clean-keystone   Stop and remove Keystone service with volumes"
	@echo "  clean-barbican   Stop and remove Barbican service with volumes"
	@echo ""
	@echo "Usage examples:"
	@echo "  make postgres    # Start PostgreSQL"
	@echo "  make clean       # Clean up all services"

# Build the base container image
build-base:
	@echo "Building base container image..."
	cd container && buildah bud --format=docker -t openstack/mybase:1.0 .

build-dev:
	@echo "Building dev container image..."
	cd container && buildah bud --format=docker -t openstack/mydev:1.0 -f Dockerfile.dev

build-ans:
	@echo "Building ansible container image..."
	cd container && buildah bud --format=docker -t openstack/myans:1.0 -f Dockerfile.ans

# Start PostgreSQL service
postgres:
	@echo "Starting PostgreSQL service..."
	podman-compose -f postgres-compose.yml up

# Start Keystone service
keystone:
	@echo "Starting Keystone service..."
	podman-compose -f keystone-compose.yml up

# Start Barbican service
barbican:
	@echo "Starting Barbican service..."
	podman-compose -f barbican-compose.yml up

# Test Barbican encrypt & decrpyt
barbican-test-enc:
	@echo "Starting Test Barbican encrypt & decrypt..."
	podman-compose -f barbican-compose-test-encrypt.yml up

# Test Barbican cert sign & verify
barbican-test-sign:
	@echo "Starting Test Barbican cert sign & verify..."
	podman-compose -f barbican-compose-test-sign.yml up

# Test Barbican ansible vault
barbican-test-vault:
	@echo "Starting Test Barbican ansible vault..."
	#rm ansible-sample-project/inventory/group_vars/all.yml
	cp ansible-sample-project/inventory/group_vars/all.yml.org ansible-sample-project/inventory/group_vars/all.yml
	podman-compose -f barbican-compose-test-vault.yml up

# Test Barbican rewrap
barbican-test-rewrap:
	@echo "Starting Test Barbican rewrap..."
	podman-compose -f barbican-compose-test-rewrap.yml up

barbican-dev:
	@echo "Starting Barbican dev service..."
	podman-compose -f barbican-compose-dev.yml up

barbican-rewrap:
	@echo "Starting Barbican dev service..."
	podman-compose -f barbican-compose.rewrap.yml up

# Clean up all services
clean: clean-barbican clean-keystone clean-postgres
	@echo "All services cleaned up"

# Clean up PostgreSQL service
clean-postgres:
	@echo "Cleaning up PostgreSQL service..."
	podman-compose -f postgres-compose.yml down -v

# Clean up Keystone service
clean-keystone:
	@echo "Cleaning up Keystone service..."
	podman-compose -f keystone-compose.yml down -v

# Clean up Barbican service
clean-barbican:
	@echo "Cleaning up Barbican service..."
	podman-compose -f barbican-compose.yml down -v
	awk '/# p11-config-marker/ {print; exit} {print}' ./config/barbican.conf > ./config/barbican.conf.tmp && mv ./config/barbican.conf.tmp ./config/barbican.conf

clean-barbican-dev:
	@echo "Cleaning up Barbican dev service..."
	podman-compose -f barbican-compose-dev.yml down -v
	awk '/# p11-config-marker/ {print; exit} {print}' ./config/barbican.conf > ./config/barbican.conf.tmp && mv ./config/barbican.conf.tmp ./config/barbican.conf

db-clean-barbican:
	podman exec -it barbican_postgres psql -U postgres postgres -c "DROP DATABASE barbican;"
	podman exec -it barbican_postgres psql -U postgres postgres -c "CREATE DATABASE barbican;"
