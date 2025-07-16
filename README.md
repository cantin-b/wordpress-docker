# Running Wordpress with Docker

---

## 🚀 Docker Commands – Getting Started

Here are the basic commands you'll use to manage your WordPress Docker stack:

### Start the project

```bash
docker compose up -d
```

* Starts the containers in the background
* Downloads the images if needed

### Stop the project

```bash
docker compose down
```

* Stops and removes containers (but keeps volumes)

### Restart the stack

```bash
docker compose down && docker compose up -d
```

### View running containers

```bash
docker ps
```

* Shows active containers with ports and uptime

### View container logs

```bash
docker logs wordpress
docker logs wordpress_db
```

* Useful to debug issues in WordPress or MySQL

### Enter a container shell

```bash
docker exec -it wordpress bash
docker exec -it wordpress_db bash
```

* Run shell commands directly inside the container

### Stop individual container

```bash
docker stop wordpress
docker stop wordpress_db
```

### Rebuild images (if Dockerfile used)

```bash
docker compose build --no-cache
```

---

## 1. Project Structure

```
portfolio-blog-wp/
├── backup/                         # Backups (DB + wp-content)
├── wp-content/                     # Themes, plugins, media
├── docker-compose.yml              # Docker config
├── backup.sh                       # Backup script (local or server)
├── restore.sh                      # Restore on same machine
└── restore-on-new-server.sh        # Restore on a new server (IP update included)
```

---

## 2. docker-compose.yml

```yaml
version: '3.9'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: wpdb
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: wppass
    volumes:
      - ./wp-content:/var/www/html/wp-content

  db:
    image: mysql:5.7
    container_name: wordpress_db
    restart: always
    environment:
      MYSQL_DATABASE: wpdb
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: wppass
      MYSQL_ROOT_PASSWORD: rootpass
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

---

## 3. backup.sh (Backup DB + wp-content)

```bash
#!/bin/bash

BACKUP_DIR="./backup"
CONTENT_DIR="./wp-content"
DB_CONTAINER="wordpress_db"
DB_NAME="wpdb"
DB_USER="wpuser"
DB_PASS="wppass"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "📦 Dumping database..."
docker exec "$DB_CONTAINER" sh -c "exec mysqldump -u$DB_USER -p$DB_PASS $DB_NAME" > "$BACKUP_DIR/wpdb-$DATE.sql"

echo "🗂 Archiving wp-content..."
tar -czf "$BACKUP_DIR/wp-content-$DATE.tar.gz" -C "$CONTENT_DIR" .

echo "✅ Backup saved in $BACKUP_DIR"
```

```bash
chmod +x backup.sh
```

---

## 4. restore.sh (Restore on same machine)

```bash
#!/bin/bash

BACKUP_DIR="./backup"
CONTENT_DIR="./wp-content"
DB_CONTAINER="wordpress_db"
DB_NAME="wpdb"
DB_USER="wpuser"
DB_PASS="wppass"

LATEST_SQL=$(ls -t $BACKUP_DIR/wpdb-*.sql | head -n 1)
LATEST_CONTENT=$(ls -t $BACKUP_DIR/wp-content-*.tar.gz | head -n 1)

echo "🗂 Restoring wp-content..."
tar -xzf "$LATEST_CONTENT" -C "$CONTENT_DIR"

echo "🐳 Starting Docker containers..."
docker compose up -d

echo "📥 Importing SQL backup..."
docker cp "$LATEST_SQL" $DB_CONTAINER:/wpdb.sql
docker exec -i $DB_CONTAINER sh -c "mysql -u$DB_USER -p$DB_PASS $DB_NAME < /wpdb.sql"

echo "✅ Local restore complete"
```

```bash
chmod +x restore.sh
```

---

## 5. restore-on-new-server.sh (for new IPs or VPS)

```bash
#!/bin/bash

BACKUP_DIR="./backup"
CONTENT_DIR="./wp-content"
DB_CONTAINER="wordpress_db"
DB_NAME="wpdb"
DB_USER="wpuser"
DB_PASS="wppass"
NEW_IP="<IP>"   
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
```

```bash
chmod +x restore-on-new-server.sh
```

---

## Deployment Steps on New Server

1. **Transfer project to server**:

   ```bash
   scp -r portfolio-blog-wp ubuntu@NEW_SERVER_IP:~
   ```

2. **SSH and restore**:

   ```bash
   ssh ubuntu@NEW_SERVER_IP
   cd ~/portfolio-blog-wp
   ./restore-on-new-server.sh
   ```

3. **Set your domain**:

After restoring, edit your wp-config.php inside the wordpress container:

```php
define('WP_HOME', 'https://mywebsite.com');
define('WP_SITEURL', 'https://mywebsite.com');
```

3. **Configure your NGINX reverse proxy**:

Set up NGINX on the host to proxy traffic from HTTPS (port 443) to the internal WordPress container (port 8080)

---

## Done

Your WordPress site will be up at:

```
https://mywebsite.com
```
