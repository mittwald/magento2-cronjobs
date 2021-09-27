#!/bin/sh

# Author: Daniel Kraemer <d.kraemer@mittwald.de> for Mittwald CM Service GmbH & Co. KG
# Author: Daniel Wolf <d.wolf@mittwald.de> for Mittwald CM Service GmbH & Co. KG
# Description: Cronjob for Magento2.
# Default: http://devdocs.magento.com/guides/v2.0/config-guide/cli/config-cli-subcommands-cron.html

# Please report bugs and feedback to
# https://github.com/mittwald/magento2-cronjobs/issues

LOCKFILE="${HOME}/tmp/cron.lock"
PHP_BIN="$(command -v php)"
ABSOLUTE_PATH=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)/$(basename "${BASH_SOURCE[0]}")
INSTALLDIR="${ABSOLUTE_PATH%/*}"

function cleanup() {
    for cpid in "$(jobs -p)"; do kill "$cpid"; done
    rm -f "${LOCKFILE}"
}

trap cleanup 1 2 3 6 9 15

if [ ! -f "${LOCKFILE}" ] || [ "$(find ${LOCKFILE} -mmin +59)" ]; then
    echo "$$" > "${LOCKFILE}"
else
    exit 0
fi

${PHP_BIN} "${INSTALLDIR}/bin/magento" cron:run >> "${INSTALLDIR}/var/log/setup.cron.log" 
${PHP_BIN} "${INSTALLDIR}/update/cron.php" >> "${INSTALLDIR}/var/log/update.cron.log"

MAGEVERSION=$( ${PHP_BIN} "${INSTALLDIR}/bin/magento" --version )
MAGEVERSIONMINOR=$( echo ${MAGEVERSION} | awk -F'.' '{print $2}' )
MAGEVERSIONPATCHLEVEL=$( echo ${MAGEVERSION} | awk -F'.' '{print $3}' | awk -F'-' '{print $1}' )

if [ ${MAGEVERSIONMINOR} -le 3 ] && [ ${MAGEVERSIONPATCHLEVEL} -le 6 ]; then
        ${PHP_BIN} "${INSTALLDIR}/bin/magento" setup:cron:run >> "${INSTALLDIR}/var/log/setup.cron.log"
fi

wait

rm -f "${LOCKFILE}"

exit 0
