# Barbican Development Environment

This repository provides a podman-compose configuration for setting up a Barbican development environment with PostgreSQL, and OpenStack Keystone services.

## Prerequisites

- RHEL9 or compatible system (Rocky Linux 9.5 or equivalent)
- Podman and podman-compose installed
- Internet access for downloading Rocky Linux containers and OpenStack repositories

## Services

The development environment includes:

1. **PostgreSQL**: Database for Barbican and Keystone
2. **Keystone**: OpenStack Identity service with Apache/mod_wsgi
3. **Barbican**: OpenStack KeyManager service with Apache/mod_wsgi

## Prerequisites

- RHEL9 or compatible system (Rocky Linux 9.5 or equivalent)
- Podman and podman-compose installed
- Internet access for downloading Rocky Linux containers and OpenStack repositories
- Build Base Container

## Builld Base Container

```bash
cd container
buildah bud --format=docker -t openstack/mybase:1.0 .
```

## Quick Start

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

## cleanup

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


