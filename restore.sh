#!/bin/bash

BACKUP_DIR="./backup"
CONTENT_DIR="./wp-content"
DB_CONTAINER="wordpress_db"
DB_NAME="wpdb"
DB_USER="wpuser"
DB_PASS="wppass"

LATEST_SQL=$(ls -t $BACKUP_DIR/wpdb-*.sql | head -n 1)
LATEST_CONTENT=$(ls -t $BACKUP_DIR/wp-content-*.tar.gz | head -n 1)

echo "Restoring wp-content..."
tar -xzf "$LATEST_CONTENT" -C "$CONTENT_DIR"

echo "Starting Docker containers..."
docker compose up -d

echo "Importing SQL backup..."
docker cp "$LATEST_SQL" $DB_CONTAINER:/wpdb.sql
docker exec -i $DB_CONTAINER sh -c "mysql -u$DB_USER -p$DB_PASS $DB_NAME < /wpdb.sql"

echo "Local restore complete"

# to be able to execute the script run:
# chmod +x restore.sh
