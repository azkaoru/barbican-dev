CREATE DATABASE keystone;
CREATE DATABASE barbican;
CREATE USER keystone WITH PASSWORD 'keystone' superuser;
CREATE USER barbican WITH PASSWORD 'barbican' superuser;
ALTER ROLE postgres set bytea_output to escape;
ALTER ROLE keystone set bytea_output to escape;
ALTER ROLE barbican set bytea_output to escape;
