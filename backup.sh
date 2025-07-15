#!/bin/bash

# === CONFIGURATION ===
BACKUP_DIR="./backup"
CONTENT_DIR="./wp-content"
DB_CONTAINER="wordpress_db"
DB_NAME="wpdb"
DB_USER="wpuser"
DB_PASS="wppass"
DATE=$(date +%Y%m%d-%H%M%S)

# === CRÉER DOSSIER DE SAUVEGARDE SI BESOIN ===
mkdir -p "$BACKUP_DIR"

# === SAUVEGARDE DE LA BASE DE DONNÉES ===
echo "Sauvegarde de la base de données..."
docker exec "$DB_CONTAINER" sh -c "exec mysqldump -u$DB_USER -p$DB_PASS $DB_NAME" > "$BACKUP_DIR/wpdb-$DATE.sql"

# === SAUVEGARDE DE WP-CONTENT ===
echo "Sauvegarde de wp-content..."
tar -czf "$BACKUP_DIR/wp-content-$DATE.tar.gz" -C "$CONTENT_DIR" .

# === TERMINÉ ===
echo "Sauvegardes terminées dans le dossier: $BACKUP_DIR"


# to be able to execute the script run:
# chmod +x backup.sh
