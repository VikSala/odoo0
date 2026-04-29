#!/bin/bash

# --- CONFIGURACIÓN ---
CONTAINER_DB="odoo0-db-1"
CONTAINER_ODOO="odoo0-odoo-1"
DB_A_ELIMINAR="test"  # <--- Base de datos a borrar
POSTGRES_USER="odoo"

# 1. VALIDACIÓN INICIAL: Evitar variables vacías
if [ -z "$DB_A_ELIMINAR" ] || [ "${#DB_A_ELIMINAR}" -lt 3 ]; then
    echo "❌ ERROR: El nombre de la base de datos es demasiado corto o está vacío."
    exit 1
fi

# 2. RESUMEN Y CONFIRMACIÓN
echo "----------------------------------------------------------"
echo "⚠️  ADVERTENCIA DE ELIMINACIÓN TOTAL ⚠️"
echo "----------------------------------------------------------"
echo "Base de Datos SQL:  $DB_A_ELIMINAR (en $CONTAINER_DB)"
echo "Carpeta Filestore: /var/lib/odoo/filestore/$DB_A_ELIMINAR"
echo "----------------------------------------------------------"
read -p "¿Estás seguro de que quieres BORRAR TODO? (s/n): " CONFIRMACION

if [[ "$CONFIRMACION" != "s" && "$CONFIRMACION" != "S" ]]; then
    echo "🚫 Operación cancelada por el usuario."
    exit 0
fi

echo "🚀 Iniciando eliminación..."

# 3. Matar conexiones activas
echo "🔒 Terminando procesos activos de $DB_A_ELIMINAR..."
sudo docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d postgres -c \
"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_A_ELIMINAR' AND pid <> pg_backend_pid();"

# 4. Borrar Base de Datos en PostgreSQL
echo "📦 Eliminando base de datos en PostgreSQL..."
sudo docker exec -t $CONTAINER_DB dropdb -U $POSTGRES_USER $DB_A_ELIMINAR

# 5. Borrar Filestore (Con doble chequeo de variable)
echo "📁 Eliminando archivos del Filestore..."
sudo docker exec -u root -t $CONTAINER_ODOO bash -c "
if [ -n '$DB_A_ELIMINAR' ] && [ -d /var/lib/odoo/filestore/$DB_A_ELIMINAR ]; then
    rm -rf /var/lib/odoo/filestore/$DB_A_ELIMINAR
    echo '✅ Carpeta de filestore eliminada correctamente.'
else
    echo 'ℹ️  No se encontró carpeta física para $DB_A_ELIMINAR, nada que borrar en disco.'
fi"

echo "✨ Proceso finalizado. La base de datos '$DB_A_ELIMINAR' ha sido eliminada."
