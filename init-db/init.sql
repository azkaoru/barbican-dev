CREATE DATABASE keystone;
CREATE USER keystone WITH PASSWORD 'keystone';

-- Grant privileges to keystone user on keystone database
GRANT ALL PRIVILEGES ON DATABASE keystone TO keystone;
    
-- Grant privileges to barbican user on keystone database
GRANT ALL PRIVILEGES ON DATABASE keystone TO barbican;


