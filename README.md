# Barbican Development Environment

This repository provides a podman-compose configuration for setting up a Barbican development environment with PostgreSQL, Memcached, and OpenStack Keystone services.

## Prerequisites

- RHEL9 or compatible system (Rocky Linux 9.5 or equivalent)
- Podman and podman-compose installed
- Internet access for downloading Rocky Linux containers and OpenStack repositories

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

## Building and Installing Barbican on RHEL9

Once the supporting services are running, you can build and install Barbican from source:

### Prerequisites for Barbican Development

1. Install Python development tools:
```bash
sudo dnf install python3-devel python3-pip git gcc
```

2. Install additional system dependencies:
```bash
sudo dnf install libffi-devel openssl-devel sqlite-devel
```

### Building Barbican from Source

1. Clone the Barbican repository:
```bash
git clone https://github.com/openstack/barbican.git
cd barbican
```

2. Create a Python virtual environment:
```bash
python3 -m venv barbican-venv
source barbican-venv/bin/activate
```

3. Upgrade pip and install dependencies:
```bash
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
pip install -r test-requirements.txt
```

4. Install Barbican in development mode:
```bash
pip install -e .
```

### Configuring Barbican

1. Create the configuration directory:
```bash
sudo mkdir -p /etc/barbican
sudo chown $(whoami):$(whoami) /etc/barbican
```

2. Copy sample configuration files:
```bash
cp etc/barbican/barbican.conf.sample /etc/barbican/barbican.conf
cp etc/barbican/barbican-api-paste.ini /etc/barbican/
```

   **Alternative**: Use the sample configuration provided in this repository:
```bash
cp barbican-dev/config/barbican.conf.sample /etc/barbican/barbican.conf
```

3. Edit `/etc/barbican/barbican.conf` to configure database and Keystone:
```ini
[DEFAULT]
sql_connection = postgresql://barbican:barbican@localhost:5432/barbican
# Use fake transport for development (no RabbitMQ required)
transport_url = fake://

[keystone_authtoken]
auth_url = http://localhost:5000/v3
www_authenticate_uri = http://localhost:5000/v3
auth_type = password
project_domain_id = default
user_domain_id = default
project_name = service
username = barbican
password = barbican
memcached_servers = localhost:11211

[keystone_notifications]
enable = True
```

**Note**: The `transport_url = fake://` configuration uses a fake messaging driver suitable for development and testing. For production deployments, you would typically use RabbitMQ (`rabbit://`) or another production-ready messaging system.

### Running Barbican in Debug Mode

1. Ensure the supporting services are running:
```bash
podman-compose up -d
```

2. Initialize the Barbican database:
```bash
source barbican-venv/bin/activate
barbican-db-manage upgrade
```

3. Start Barbican in debug mode:
```bash
# Start the API server in debug mode
barbican-api --debug --config-file=/etc/barbican/barbican.conf

# Or use uwsgi for development (in another terminal)
uwsgi --http :9311 --wsgi-file barbican/api/app.py --callable application --enable-threads
```

4. Start the worker process (in another terminal):
```bash
source barbican-venv/bin/activate
barbican-worker --debug --config-file=/etc/barbican/barbican.conf
```

### Verifying Barbican Installation

1. Test the API endpoint:
```bash
curl http://localhost:9311/v1/secrets
```

2. Use the Barbican client:
```bash
pip install python-barbicanclient
export OS_AUTH_URL=http://localhost:5000/v3
export OS_USERNAME=admin
export OS_PASSWORD=admin123
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_IDENTITY_API_VERSION=3

barbican secret store --payload="my secret data"
```

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

4. Validate the development environment setup:
```bash
./validate-setup.sh
```

## Environment Variables

You can customize the configuration by setting environment variables in the podman-compose.yml file or creating a .env file.

## Troubleshooting

### Common Issues

1. **RabbitMQ Connection Refused Error**:
   If you see errors like "Connection refused" when running `barbican-worker`, ensure your `/etc/barbican/barbican.conf` includes:
   ```ini
   [DEFAULT]
   transport_url = fake://
   ```
   This configures barbican to use a fake messaging driver instead of trying to connect to RabbitMQ, which is not provided in this development environment.

2. **Check service health**:
```bash
podman-compose ps
```

3. **View service logs**:
```bash
podman-compose logs <service-name>
```

4. **Restart services**:
```bash
podman-compose restart
```

5. **Clean up and restart**:
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
