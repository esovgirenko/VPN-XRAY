#!/usr/bin/env bash
# Исправление config.json для Xray v26: fingerprint только у клиента; dest → target.
# Запуск: sudo bash server/fix-config-v26.sh

set -e
CONFIG_FILE="/usr/local/etc/xray/config.json"

[[ $EUID -eq 0 ]] || { echo "Запустите с sudo"; exit 1; }
[[ -f "${CONFIG_FILE}" ]] || { echo "Не найден ${CONFIG_FILE}"; exit 1; }

CHANGED=0
# 1) Удалить fingerprint из server realitySettings (в v26 только у клиента)
if jq -e '.inbounds[0].streamSettings.realitySettings.fingerprint' "${CONFIG_FILE}" >/dev/null 2>&1; then
    jq 'del(.inbounds[0].streamSettings.realitySettings.fingerprint)' "${CONFIG_FILE}" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "${CONFIG_FILE}"
    echo "[OK] Удалён fingerprint из realitySettings."
    CHANGED=1
fi
# 2) В v26 серверный REALITY ожидает "target", а не "dest"
if jq -e '.inbounds[0].streamSettings.realitySettings.dest' "${CONFIG_FILE}" >/dev/null 2>&1; then
    DEST_VAL=$(jq -r '.inbounds[0].streamSettings.realitySettings.dest' "${CONFIG_FILE}")
    jq --arg t "${DEST_VAL}" 'del(.inbounds[0].streamSettings.realitySettings.dest) | .inbounds[0].streamSettings.realitySettings.target = $t' "${CONFIG_FILE}" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "${CONFIG_FILE}"
    echo "[OK] Заменён dest на target."
    CHANGED=1
fi

if [[ ${CHANGED} -eq 0 ]]; then
    echo "Изменений не требуется. Проверяю конфиг запуском Xray..."
fi

# Перезапуск и проверка
systemctl restart xray
sleep 2
if systemctl is-active --quiet xray; then
    echo "[OK] Xray запущен."
    exit 0
fi

# Если не запустился — выводим полный текст ошибки
echo "[ОШИБКА] Xray не запустился. Полный вывод:"
/usr/local/bin/xray run -config "${CONFIG_FILE}" 2>&1 || true
exit 1
