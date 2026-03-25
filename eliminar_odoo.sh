#!/bin/bash

# Detectar nombre de la carpeta actual
PROJECT=$(basename "$PWD")

# --- CONFIGURACIÓN CORREGIDA ---
CONTAINER_DB="${PROJECT}-db-1"
CONTAINER_ODOO="${PROJECT}-odoo-1"
DB_A_ELIMINAR="test"
POSTGRES_USER="odoo"

echo "🗑️  Iniciando eliminación completa de la base de datos: $DB_A_ELIMINAR..."

# 1. Matar conexiones activas (Si Odoo está usando la DB, el DROP DATABASE fallaría)
echo "🔒 Terminando procesos activos de $DB_A_ELIMINAR..."
docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d postgres -c \
"SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datn>

# 2. Borrar Base de Datos en PostgreSQL
echo "📦 Eliminando base de datos en PostgreSQL..."
docker exec -t $CONTAINER_DB dropdb -U $POSTGRES_USER $DB_A_ELIMINAR

# 3. Borrar Filestore (Archivos adjuntos)
echo "📁 Eliminando archivos del Filestore..."
docker exec -u root -t $CONTAINER_ODOO bash -c "
if [ -d /var/lib/odoo/filestore/$DB_A_ELIMINAR ]; then
    rm -rf /var/lib/odoo/filestore/$DB_A_ELIMINAR
    echo '✅ Carpeta de archivos eliminada.'
else
    echo 'ℹ️  No se encontró carpeta de filestore para $DB_A_ELIMINAR.'
fi"

echo "✨ Proceso finalizado. La base de datos '$DB_A_ELIMINAR' ha desaparecido por completo."
