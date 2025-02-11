#!/bin/bash

# Set PostgreSQL credentials
PG_USER="test-Hiranmai"
PG_HOST="test-Hiranmai"
PG_PORT="5432"
BACKUP_DIR="/path/to/backup"
S3_BUCKET="s3://test-bucket"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Get list of databases (excluding template and system databases)
DB_LIST=$(psql -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname <> 'postgres';")

# Loop through each database
for DB in $DB_LIST; do
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    DB_BACKUP_DIR="$BACKUP_DIR/$DB"
    mkdir -p "$DB_BACKUP_DIR"
    BACKUP_FILE="$DB_BACKUP_DIR/${DB}_$TIMESTAMP.sql.gz"
    
    echo "Backing up database: $DB"
    pg_dump -U "$PG_USER" -h "$PG_HOST" -p "$PG_PORT" -d "$DB" | gzip > "$BACKUP_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Backup successful: $BACKUP_FILE"
        aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/$DB/"
        if [ $? -eq 0 ]; then
            echo "Upload successful: $S3_BUCKET/$DB/"
        else
            echo "Upload failed for: $DB"
        fi
    else
        echo "Backup failed for: $DB"
    fi

done

echo "Backup process completed."
