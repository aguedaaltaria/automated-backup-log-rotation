#!/usr/bin/env bash

# ==============================================================================
# Script: backup.sh
# Propósito: Empaquetar y comprimir directorios de forma segura en Linux.
# ==============================================================================

# 1. Modo estricto de seguridad en Bash:
# Si un comando falla, el script se detiene de inmediato en lugar de continuar a ciegas.
set -o errexit
# Si intentamos usar una variable que no existe o está vacía por error, se detiene.
set -o nounset
# Si una tubería (pipe) falla a mitad de camino, se considera error total.
set -o pipefail

# 2. Localizar dónde estamos parados:
# Esta línea averigua la ruta exacta donde vive este script en tu sistema.
DIRECTORIO_DEL_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Calculamos la ruta hacia el archivo de configuración (está una carpeta arriba, en config/)
ARCHIVO_CONFIGURACION="${DIRECTORIO_DEL_SCRIPT}/../config/backup.conf"

# 3. Comprobar que el archivo de configuración existe:
if [ ! -f "${ARCHIVO_CONFIGURACION}" ]; then
    echo "Error: No se encontró el archivo de configuración en ${ARCHIVO_CONFIGURACION}" >&2
    exit 1
fi

# 4. Importar las variables de backup.conf:
# El comando 'source' lee ese archivo y carga DIRECTORIO_ORIGEN, DIRECTORIO_DESTINO, etc.
source "${ARCHIVO_CONFIGURACION}"

# 5. Comprobar que la carpeta de origen existe y tiene cosas para respaldar:
if [ ! -d "${DIRECTORIO_ORIGEN}" ]; then
    echo "Error: El directorio de origen no existe: ${DIRECTORIO_ORIGEN}" >&2
    exit 1
fi

# 6. Comprobar si existe la carpeta destino; si no existe, la creamos:
if [ ! -d "${DIRECTORIO_DESTINO}" ]; then
    echo "El directorio de destino no existía. Creándolo en: ${DIRECTORIO_DESTINO}"
    mkdir -p "${DIRECTORIO_DESTINO}"
fi

# 7. Obtener la fecha y hora actual para el nombre (ejemplo: 2026-11-09_17-50-00):
FECHA_ACTUAL="$(date +'%Y-%m-%d_%H-%M-%S')"
NOMBRE_PAQUETE="${PREFIJO_RESPALDO}_${FECHA_ACTUAL}.tar.gz"
RUTA_FINAL="${DIRECTORIO_DESTINO}/${NOMBRE_PAQUETE}"

echo "=================================================="
echo "Iniciando respaldo del sistema..."
echo "Carpeta a respaldar: ${DIRECTORIO_ORIGEN}"
echo "Guardando en:        ${RUTA_FINAL}"
echo "=================================================="

# 8. Empaquetar y comprimir:
# -c: create (crear un paquete nuevo)
# -z: pasar por gzip (comprimir para que pese menos)
# -p: preservar permisos de archivos originales
# -f: nombre del archivo de salida
# Empaquetar y comprimir con soporte de exclusiones:
if [ -n "${PATRON_EXCLUSION:-}" ]; then
    echo "Aplicando exclusión para archivos: ${PATRON_EXCLUSION}"
    tar --exclude="${PATRON_EXCLUSION}" -czpf "${RUTA_FINAL}" -C "${DIRECTORIO_ORIGEN}" .
else
    tar -czpf "${RUTA_FINAL}" -C "${DIRECTORIO_ORIGEN}" .
fi

# 9. Generar la huella de seguridad (SHA-256):
sha256sum "${RUTA_FINAL}" > "${RUTA_FINAL}.sha256"

# 10. Confirmación de éxito:
TAMANIO_ARCHIVO="$(du -h "${RUTA_FINAL}" | cut -f1)"
echo "¡Respaldo completado con éxito!"
echo "Archivo: ${NOMBRE_PAQUETE}"
echo "Tamaño:  ${TAMANIO_ARCHIVO}"
echo "Firma:   ${NOMBRE_PAQUETE}.sha256"
echo "=================================================="