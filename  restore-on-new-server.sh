#!/bin/bash

BACKUP_DIR="./backup"
CONTENT_DIR="./wp-content"
DB_CONTAINER="wordpress_db"
DB_NAME="wpdb"
DB_USER="wpuser"
DB_PASS="wppass"
NEW_IP="<IP>
PORT="8080"

LATEST_SQL=$(ls -t $BACKUP_DIR/wpdb-*.sql | head -n 1)
LATEST_CONTENT=$(ls -t $BACKUP_DIR/wp-content-*.tar.gz | head -n 1)

echo "🗂 Extracting wp-content..."
tar -xzf "$LATEST_CONTENT" -C "$CONTENT_DIR"

echo "🐳 Starting containers..."
docker compose up -d

echo "📥 Importing database..."
docker cp "$LATEST_SQL" $DB_CONTAINER:/wpdb.sql
docker exec -i $DB_CONTAINER sh -c "mysql -u$DB_USER -p$DB_PASS $DB_NAME < /wpdb.sql"

echo "🌐 Updating WordPress site URL to http://$NEW_IP:$PORT"
docker exec -i $DB_CONTAINER sh -c "mysql -u$DB_USER -p$DB_PASS $DB_NAME -e \"
UPDATE wp_options SET option_value = 'http://$NEW_IP:$PORT' WHERE option_name IN ('siteurl', 'home');
\""

echo "✅ Site live at: http://$NEW_IP:$PORT"


# to be able to execute the script run:
# chmod +x restore-on-new-server.sh
