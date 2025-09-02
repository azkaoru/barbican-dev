#!/bin/bash
set -e

# Create databases for Barbican and Keystone
psql -v ON_ERROR_STOP=1 --username "$POSTGRESQL_USER" --dbname "$POSTGRESQL_DATABASE" <<-EOSQL
    -- Create keystone database and user if they don't exist
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keystone') THEN
            CREATE DATABASE keystone;
        END IF;
        
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'keystone') THEN
            CREATE USER keystone WITH PASSWORD 'keystone';
        END IF;
        
        GRANT ALL PRIVILEGES ON DATABASE keystone TO keystone;
    END
    \$\$;
    
    -- Grant privileges to barbican user on keystone database
    GRANT ALL PRIVILEGES ON DATABASE keystone TO barbican;
EOSQL

echo "Database initialization completed"