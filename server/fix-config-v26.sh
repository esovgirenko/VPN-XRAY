#!/usr/bin/env bash
# Удаление поля fingerprint из server realitySettings (в Xray v26 оно только у клиента).
# Запуск: sudo bash server/fix-config-v26.sh

set -e
CONFIG_FILE="/usr/local/etc/xray/config.json"

[[ $EUID -eq 0 ]] || { echo "Запустите с sudo"; exit 1; }
[[ -f "${CONFIG_FILE}" ]] || { echo "Не найден ${CONFIG_FILE}"; exit 1; }

if jq -e '.inbounds[0].streamSettings.realitySettings.fingerprint' "${CONFIG_FILE}" >/dev/null 2>&1; then
    jq 'del(.inbounds[0].streamSettings.realitySettings.fingerprint)' "${CONFIG_FILE}" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "${CONFIG_FILE}"
    echo "[OK] Удалён fingerprint из realitySettings (серверный конфиг)."
    systemctl restart xray
    sleep 1
    if systemctl is-active --quiet xray; then
        echo "[OK] Xray перезапущен."
    else
        echo "[ОШИБКА] Xray не запустился: journalctl -u xray -n 20"
        exit 1
    fi
else
    echo "Поле fingerprint отсутствует в конфиге — ничего менять не нужно."
fi
