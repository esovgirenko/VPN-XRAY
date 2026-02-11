#!/usr/bin/env bash
# Создаёт виртуальное окружение и ставит зависимости (для Debian/Ubuntu с PEP 668)
set -e
cd "$(dirname "$0")"
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
echo "Готово. Запуск: .venv/bin/python reality-link-gen.py ... или: source .venv/bin/activate && python reality-link-gen.py ..."
