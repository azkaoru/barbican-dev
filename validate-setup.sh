#!/bin/bash
# Validation script for barbican development environment setup

set -e

echo "Barbican Development Environment Validation"
echo "=========================================="

# Check if sample config exists
if [ -f "/home/runner/work/barbican-dev/barbican-dev/config/barbican.conf.sample" ]; then
    echo "✓ Sample barbican configuration found"
else
    echo "✗ Sample barbican configuration missing"
    exit 1
fi

# Validate configuration syntax
if python3 -c "
import configparser
config = configparser.ConfigParser()
config.read('/home/runner/work/barbican-dev/barbican-dev/config/barbican.conf.sample')
transport_url = config.get('DEFAULT', 'transport_url', fallback='')
if transport_url == 'fake://':
    print('✓ Transport URL correctly set to fake://')
else:
    print('✗ Transport URL not set correctly')
    exit(1)
" 2>/dev/null; then
    echo "✓ Configuration syntax is valid"
else
    echo "✗ Configuration syntax error"
    exit 1
fi

# Check if compose file exists and includes necessary services
if [ -f "/home/runner/work/barbican-dev/barbican-dev/podman-compose.yml" ]; then
    echo "✓ Podman compose file found"
    
    # Check for required services
    if grep -q "postgres" /home/runner/work/barbican-dev/barbican-dev/podman-compose.yml; then
        echo "✓ PostgreSQL service configured"
    else
        echo "✗ PostgreSQL service missing"
        exit 1
    fi
    
    if grep -q "memcached" /home/runner/work/barbican-dev/barbican-dev/podman-compose.yml; then
        echo "✓ Memcached service configured"
    else
        echo "✗ Memcached service missing"
        exit 1
    fi
    
    if grep -q "keystone" /home/runner/work/barbican-dev/barbican-dev/podman-compose.yml; then
        echo "✓ Keystone service configured"
    else
        echo "✗ Keystone service missing"
        exit 1
    fi
    
    # Verify no RabbitMQ is configured (which would conflict with fake transport)
    if grep -q -i "rabbit\|amqp" /home/runner/work/barbican-dev/barbican-dev/podman-compose.yml; then
        echo "! Warning: RabbitMQ/AMQP configuration found in compose file"
    else
        echo "✓ No conflicting RabbitMQ configuration found"
    fi
else
    echo "✗ Podman compose file missing"
    exit 1
fi

echo ""
echo "Environment validation completed successfully!"
echo ""
echo "Summary:"
echo "- Sample barbican configuration includes 'transport_url = fake://' to prevent RabbitMQ connection issues"
echo "- Development environment provides PostgreSQL, Memcached, and Keystone services"
echo "- No RabbitMQ service is required with this configuration"
echo ""
echo "To use this configuration:"
echo "1. Start services: podman-compose up -d"
echo "2. Copy sample config: cp config/barbican.conf.sample /etc/barbican/barbican.conf"
echo "3. Run barbican-worker: barbican-worker --debug --config-file=/etc/barbican/barbican.conf"