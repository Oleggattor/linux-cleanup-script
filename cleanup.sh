#!/bin/bash



# 📝 Лог-файл



LOG_FILE="/var/log/system_cleanup_$(date +%Y%m%d).log"



CURRENT_KERNEL="$(uname -r)"



export LC_ALL=C



# Проверка прав



if [ "$(id -u)" -ne 0 ]; then



echo "⚠️ Скрипт требует запуск от root (через sudo)!"



exit 1



fi



# Создание лога



touch "$LOG_FILE" && chmod 640 "$LOG_FILE"



echo "🧹 Чистка системы началась..." | tee -a "$LOG_FILE"



echo "📄 Лог: $LOG_FILE" | tee -a "$LOG_FILE"



echo "--------------------------------------" | tee -a "$LOG_FILE"



{



echo "=== $(date '+%F %T') ==="



echo "⚠️ Текущее активное ядро: $CURRENT_KERNEL"



echo



# 💾 Дисковое пространство до



echo "💾 Свободное место до очистки:"



df -h /



# 🔄 Обновление пакетов (если требуется — раскомментируй)



# echo "🔄 Обновление списка пакетов..."



# apt update && apt upgrade -y



# 🗑️ Очистка APT



echo "🗑️ Очистка apt..."



apt autoremove -y



apt autoclean



apt clean



# 🔧 Исправление ошибок пакетов



echo "🔧 Проверка и исправление битых пакетов..."



apt install -f -y



dpkg -C || echo "⚠️ Есть проблемы с dpkg, проверьте вручную."



# 📁 Очистка логов



echo "📁 Очистка systemd-журналов (старше 7 дней)..."



journalctl --vacuum-time=7d



# 🧼 Очистка кэша и корзин пользователей



echo "🧼 Очистка кэша и мусора пользователей..."



for home in /home/*; do



[ -d "$home" ] || continue



user=$(basename "$home")



echo "→ $user"



rm -rf "$home/.cache/"* "$home/.local/share/Trash/"* 2>/dev/null



done



# 🧽 Очистка /tmp (без удаления сокетов и пайпов)



echo "🧽 Очистка /tmp..."



find /tmp -mindepth 1 -maxdepth 1 -mtime +1 ! -type s ! -type p -exec rm -rf {} + 2>/dev/null



# 📦 Установка и запуск deborphan



if ! command -v deborphan >/dev/null 2>&1; then



echo "📦 Установка deborphan..."



apt install -y deborphan



fi



echo "🔎 Поиск осиротевших библиотек..."



orphans=$(deborphan 2>/dev/null)



if [ -n "$orphans" ]; then



echo "Удаление: $orphans"



apt remove -y --purge $orphans



else



echo "Осиротевших библиотек не найдено."



fi



# 🧨 Удаление старых ядер (без текущего)



echo "🧨 Поиск и удаление старых ядер..."



dpkg -l | awk '/^ii linux-image-[0-9]/ { print $2 }' | grep -v "$CURRENT_KERNEL" | while read -r kernel; do



echo "Удаляется: $kernel"



apt remove -y --purge "$kernel"



done



# 💾 Дисковое пространство после



echo



echo "💾 Свободное место после очистки:"



df -h /



echo



echo "✅ Готово! Система почищена и проверена."



} 2>&1 | tee -a "$LOG_FILE"



echo "--------------------------------------" | tee -a "$LOG_FILE"



echo "📄 Лог записан в: $LOG_FILE" | tee -a "$LOG_FILE"
