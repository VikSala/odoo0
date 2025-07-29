a. Creas los volúmenes:

docker volume create odoo-18-0-docker_odoo-web-data
docker volume create odoo-18-0-docker_odoo-db-data

b. Importas el contenido:

docker run --rm -v odoo-18-0-docker_odoo-web-data:/volume -v $(pwd):/backup alpine sh -c "cd /volume && tar xzf /backup/odoo-web-data.tar.gz"
docker run --rm -v odoo-18-0-docker_odoo-db-data:/volume -v $(pwd):/backup alpine sh -c "cd /volume && tar xzf /backup/odoo-db-data.tar.gz"
