#!/bin/bash

# Detectar nombre de la carpeta actual
PROJECT=$(basename "$PWD")

# Nombre de la base de datos
DB_NAME=$PROJECT

# Contenedor postgres (docker compose)
DB_CONTAINER="${PROJECT}-db-1"

echo "Proyecto detectado: $PROJECT"
echo "Base de datos: $DB_NAME"
echo "Contenedor DB: $DB_CONTAINER"
echo ""

echo "Limpiando assets..."

sudo docker exec -i "$DB_CONTAINER" \
psql -U odoo -d "$DB_NAME" \
-c "DELETE FROM ir_attachment WHERE url LIKE '/web/assets/%';"

echo ""
echo "Assets limpiados correctamente."
