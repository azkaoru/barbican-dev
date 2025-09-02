# Barbican Development Environment

This repository provides a podman-compose configuration for setting up a Barbican development environment with PostgreSQL, Memcached, and OpenStack Keystone services.

## Prerequisites

- RHEL9 system
- Podman and podman-compose installed
- Access to Red Hat Container Registry (registry.redhat.io)

## Services

The development environment includes:

1. **PostgreSQL 15**: Database for Barbican and Keystone
2. **Memcached**: Caching service for OpenStack components
3. **Keystone**: OpenStack Identity service with Apache/mod_wsgi

## Quick Start

1. Clone this repository:
```bash
git clone <repository-url>
cd barbican-dev
```

2. Start the services:
```bash
podman-compose up -d
```

3. Check service status:
```bash
podman-compose ps
```

4. View logs:
```bash
podman-compose logs -f
```

## Service Configuration

### PostgreSQL
- **Port**: 5432 (host network)
- **Database**: barbican
- **Username**: barbican
- **Password**: barbican
- **Admin Password**: admin123

Additional database 'keystone' is created for Keystone service.

### Memcached
- **Port**: 11211 (host network)
- **Memory**: 64MB
- **Max Connections**: 1024

### Keystone
- **Public API**: http://localhost:5000/v3
- **Admin API**: http://localhost:35357/v3
- **Admin Username**: admin
- **Admin Password**: admin123
- **Region**: RegionOne

## Network Configuration

All services use host networking mode (`network_mode: host`) for development convenience. This allows direct access to services from the host system without port mapping.

## Data Persistence

- PostgreSQL data is persisted in the `postgres_data` volume
- Keystone Fernet keys are persisted in the `keystone_fernet` volume
- Keystone logs are stored in the `./keystone-logs` directory

## Development Usage

After starting the services, you can:

1. Access Keystone API directly:
```bash
curl http://localhost:5000/v3
```

2. Connect to PostgreSQL:
```bash
psql -h localhost -U barbican -d barbican
```

3. Connect to Memcached:
```bash
telnet localhost 11211
```

## Environment Variables

You can customize the configuration by setting environment variables in the podman-compose.yml file or creating a .env file.

## Troubleshooting

1. **Check service health**:
```bash
podman-compose ps
```

2. **View service logs**:
```bash
podman-compose logs <service-name>
```

3. **Restart services**:
```bash
podman-compose restart
```

4. **Clean up and restart**:
```bash
podman-compose down
podman-compose up -d
```

## Stopping Services

To stop all services:
```bash
podman-compose down
```

To stop and remove volumes:
```bash
podman-compose down -v
```
