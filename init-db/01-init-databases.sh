#!/bin/bash
set -e

# Create databases for Barbican and Keystone
# Use postgres admin user for database creation operations
export PGPASSWORD="$POSTGRESQL_ADMIN_PASSWORD"

psql -v ON_ERROR_STOP=1 --username "postgres" --dbname "postgres" <<-EOSQL
    -- Create keystone database if it doesn't exist
    SELECT 'CREATE DATABASE keystone'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'keystone')\gexec
    
    -- Create keystone user if it doesn't exist
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'keystone') THEN
            CREATE USER keystone WITH PASSWORD 'keystone';
        END IF;
    END
    \$\$;
    
    -- Grant privileges to keystone user on keystone database
    GRANT ALL PRIVILEGES ON DATABASE keystone TO keystone;
    
    -- Grant privileges to barbican user on keystone database
    GRANT ALL PRIVILEGES ON DATABASE keystone TO barbican;
EOSQL

echo "Database initialization completed"