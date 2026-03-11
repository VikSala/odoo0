#!/bin/bash

# Detectar nombre de la carpeta actual
PROJECT=$(basename "$PWD")

# --- CONFIGURACIÓN CORREGIDA ---
CONTAINER_DB="${PROJECT}-db-1"
CONTAINER_ODOO="${PROJECT}-odoo-1"
DB_ORIGEN=$PROJECT
DB_DESTINO="test"
POSTGRES_USER="odoo"

echo "🚀 Iniciando duplicado de $DB_ORIGEN a $DB_DESTINO..."

# 1. Forzar cierre de conexiones activas
echo "🔒 Cerrando conexiones activas en $DB_ORIGEN..."
docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d postgres -c \
"SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity>

# 2. Clonar la base de datos
echo "📦 Clonando base de datos (PostgreSQL)..."
docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d postgres -c \
"CREATE DATABASE \"$DB_DESTINO\" WITH TEMPLATE \"$DB_ORIGEN\" OWNER $POSTGRES_USER;"

# 3. Desactivar envío de correos en la base TEST (Seguridad)
echo "📧 Desactivando servidores de correo en la copia..."
docker exec -t $CONTAINER_DB psql -U $POSTGRES_USER -d $DB_DESTINO -c \
"UPDATE ir_mail_server SET active = false; UPDATE fetchmail_server SET active = false;"

# 4. Duplicar el Filestore
echo "📁 Duplicando Filestore..."
docker exec -u root -t $CONTAINER_ODOO bash -c "
if [ -d /var/lib/odoo/filestore/$DB_ORIGEN ]; then
    rm -rf /var/lib/odoo/filestore/$DB_DESTINO
    cp -a /var/lib/odoo/filestore/$DB_ORIGEN /var/lib/odoo/filestore/$DB_DESTINO
    chown -R odoo:odoo /var/lib/odoo/filestore/$DB_DESTINO
    echo '✅ Filestore copiado con éxito.'
else
    echo '⚠️ Error: No se encontró el filestore en /var/lib/odoo/filestore/$DB_ORIGEN'
fi"

echo "✨ ¡Listo! Ya puedes usar '$DB_DESTINO' sin riesgo de enviar emails reales."
