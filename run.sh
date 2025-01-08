#!/bin/bash

# Configura las banderas adicionales si se permite el acceso remoto
if [[ $ALLOW_REMOTE_ACCESS == "yes" ]]; then
    EXTRA_FLAGS="$EXTRA_FLAGS --bind-all"
fi

# Ejecuta el motor AceStream
/opt/acestream/start-engine --client-console --http-port $HTTP_PORT $EXTRA_FLAGS &

# Inicia el servicio cron para gestionar tareas programadas
service cron start

# Ejecuta runsvdir como un proceso adicional
runsvdir /app &

# Inicia Apache como proceso principal
exec apachectl -D FOREGROUND
