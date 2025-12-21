#!/bin/bash
set -e

echo "💾 Initializing production database..."

# Create databases
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE mampf_interactions;
EOSQL

# Create MaMpf user with password from environment and grant privileges
# The mampf database already exists (created by POSTGRES_DB env var)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    CREATE USER mampf WITH PASSWORD '${DB_MAMPFUSER_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE mampf TO mampf;
    GRANT ALL PRIVILEGES ON DATABASE mampf_interactions TO mampf;
EOSQL

# Grant schema privileges
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "mampf" <<-EOSQL
    GRANT ALL ON SCHEMA public TO mampf;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "mampf_interactions" <<-EOSQL
    GRANT ALL ON SCHEMA public TO mampf;
EOSQL
