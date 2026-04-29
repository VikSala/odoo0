#!/bin/bash

# --- CONFIGURACIÓN CORREGIDA ---
CONTAINER_DB="odoo0-db-1"
CONTAINER_ODOO="odoo0-odoo-1"
DB_ORIGEN="odoo0"       # Tu base de datos principal
DB_DESTINO="test"       # La copia de pruebas
POSTGRES_USER="odoo"

# 1. VALIDACIÓN DE SEGURIDAD
if [ -z "$DB_DESTINO" ] || [ "${#DB_DESTINO}" -lt 3 ]; then
    echo "❌ ERROR: El nombre de destino es demasiado corto o está vacío. Abortando para proteger el sistema."
    exit 1
fi

# 2. RESUMEN Y CONFIRMACIÓN
echo "----------------------------------------------------------"
echo "📑 RESUMEN DE DUPLICADO (CLONACIÓN)"
echo "----------------------------------------------------------"
echo "Origen (SQL + Archivos):  $DB_ORIGEN"
echo "Destino (SE SOBREESCRIBIRÁ): $DB_DESTINO"
echo "Contenedores: $CONTAINER_ODOO / $CONTAINER_DB"
echo "----------------------------------------------------------"
read -p "¿Confirmas que quieres clonar $DB_ORIGEN en $DB_DESTINO? (s/n): " CONFIRMACION

if [[ "$CONFIRMACION" != "s" && "$CONFIRMACION" != "S" ]]; then
    echo "🚫 Operación cancelada."
    exit 0
fi

echo "🚀 Iniciando proceso..."

# 3. Forzar cierre de conexiones activas
echo "🔒 Cerrando conexiones activas en $DB_ORIGEN..."
sudo docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d postgres -c \
"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_ORIGEN' AND pid <> pg_backend_pid();"

# 4. Clonar la base de datos (PostgreSQL)
# Primero borramos la de destino si ya existe para evitar errores de "database already exists"
echo "📦 Preparando base de datos de destino..."
sudo docker exec -t $CONTAINER_DB dropdb -U $POSTGRES_USER $DB_DESTINO --if-exists
sudo docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d postgres -c \
"CREATE DATABASE \"$DB_DESTINO\" WITH TEMPLATE \"$DB_ORIGEN\" OWNER $POSTGRES_USER;"

# 5. Desactivar envío de correos en la base TEST (Seguridad)
echo "📧 Desactivando servidores de correo en la copia..."
sudo docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d $DB_DESTINO -c \
"UPDATE ir_mail_server SET active = false; UPDATE fetchmail_server SET active = false;"

# 6. Duplicar el Filestore (Con protección de variable)
echo "📁 Duplicando Filestore..."
sudo docker exec -u root -t $CONTAINER_ODOO bash -c "
if [ -d /var/lib/odoo/filestore/$DB_ORIGEN ] && [ -n '$DB_DESTINO' ]; then
    rm -rf /var/lib/odoo/filestore/$DB_DESTINO
    cp -a /var/lib/odoo/filestore/$DB_ORIGEN /var/lib/odoo/filestore/$DB_DESTINO
    chown -R odoo:odoo /var/lib/odoo/filestore/$DB_DESTINO
    echo '✅ Filestore copiado con éxito.'
else
    echo '⚠️ Error: No se pudo realizar la copia del filestore.'
fi"

echo "✨ ¡Listo! Ya puedes usar '$DB_DESTINO'. Recuerda reiniciar Odoo si no aparece."
