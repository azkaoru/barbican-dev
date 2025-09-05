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