# Barbican Development Environment

This repository provides a podman-compose configuration for setting up a Barbican development environment with PostgreSQL, and OpenStack Keystone services.

## Prerequisites

- RHEL9 or compatible system (Rocky Linux 9.5 or equivalent)
- Podman and podman-compose installed
- Internet access for downloading Rocky Linux containers and OpenStack repositories

**Note**: The base container will be built automatically using `make build-base` (see Quick Start section below).

## Services

The development environment includes:

1. **PostgreSQL**: Database for Barbican and Keystone
2. **Keystone**: OpenStack Identity service with Apache/mod_wsgi
3. **Barbican**: OpenStack KeyManager service with Apache/mod_wsgi

## Quick Start

### Using Makefile (Recommended)

The Makefile provides convenient commands for managing the entire development environment.

**Important Note**: Due to startup dependencies between services, each service must be started in separate terminals in the correct order. PostgreSQL must be fully started before Keystone, and Keystone must be fully started before Barbican.

1. **Build the base container** (required first step):
```bash
make build-base
```

2. **Start services in order (each in a separate terminal)**:

   **Terminal 1 - Start PostgreSQL**:
   ```bash
   make postgres
   ```
   Wait for PostgreSQL to be fully started before proceeding.

   **Terminal 2 - Start Keystone**:
   ```bash
   make keystone
   ```
   Wait for Keystone to be fully started before proceeding.

   **Terminal 3 - Start Barbican**:
   ```bash
   make barbican
   ```

3. **Show all available commands**:
```bash
make help
```

#### Complete Workflow Example

```bash
# 1. Build the base container (one-time setup)
make build-base

# 2. Start PostgreSQL in Terminal 1
make postgres

# 3. After PostgreSQL is ready, start Keystone in Terminal 2
make keystone

# 4. After Keystone is ready, start Barbican in Terminal 3
make barbican

# 5. When done, clean up (can be run from any terminal)
make clean
```

### Using podman-compose directly

1. **Start PostgreSQL**:
```bash
podman-compose -f postgres-compose.yml up
```

2. **Start Keystone**:
```bash
podman-compose -f keystone-compose.yml up
```

3. **Start Barbican**:
```bash
podman-compose -f barbican-compose.yml up
```

## Service Configuration

### PostgreSQL
- **Port**: 5432 (host network)
- **Database**: barbican
- **Username**: barbican
- **Password**: barbican

Additional database 'keystone' is created for Keystone service.

### Keystone
- **Public API**: http://localhost:5000/v3
- **Admin API**: http://localhost:35357/v3
- **Admin Username**: admin
- **Admin Password**: admin123
- **Region**: RegionOne

## Data Persistence

- PostgreSQL data is persisted in the `postgres_data` volume
- Keystone Fernet keys are persisted in the `keystone_fernet` volume

## Cleanup

### Using Makefile (Recommended)

1. **Clean all services and data**:
```bash
make clean
```

2. **Clean individual services**:
```bash
make clean-postgres    # Clean PostgreSQL only
make clean-keystone    # Clean Keystone only  
make clean-barbican    # Clean Barbican only
```

**Note**: The `clean` commands will stop services and remove all associated volumes and data.

### Using podman-compose directly

1. **Clean Barbican**:
```bash
podman-compose -f barbican-compose.yml down -v
```

2. **Clean Keystone**:
```bash
podman-compose -f keystone-compose.yml down -v
```

3. **Clean PostgreSQL**:
```bash
podman-compose -f postgres-compose.yml  down -v
```


