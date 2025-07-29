a. Creas los volúmenes:

sudo docker volume create odoo-18-0-docker_odoo-web-data
sudo docker volume create odoo-18-0-docker_odoo-db-data

b. Importas el contenido:

sudo docker run --rm -v odoo-18-0-docker_odoo-web-data:/volume -v $(pwd):/backup alpine sh -c "cd /volume && tar xzf /backup/odoo-web-data.tar.gz"
sudo docker run --rm -v odoo-18-0-docker_odoo-db-data:/volume -v $(pwd):/backup alpine sh -c "cd /volume && tar xzf /backup/odoo-db-data.tar.gz"

c. Lanzas el contenedor:

chmod +x run.sh
sudo ./run.sh

