#!/usr/bin/env bash
# Comprueba que los comandos de datos que usa el widget devuelven el formato
# esperado: líneas IO/NET/TEMP del poll y DISK|NET de la enumeración.
set -euo pipefail

ENUM_CMD="grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //'; \
for d in /sys/block/*; do n=\${d##*/}; case \$n in nvme[0-9]*n[0-9]*|sd[a-z]*) \
[ \"\$(cat \$d/removable 2>/dev/null)\" = 0 ] || continue; \
m=\$(cat \$d/device/model 2>/dev/null | tr -s ' ' | sed 's/^ //;s/ \$//'); \
c=\$(basename \$(readlink -f \$d/device)); echo \"DISK|\$n|\$m|\$c\";; esac; done; \
for i in /sys/class/net/*; do n=\${i##*/}; [ \"\$n\" != lo ] && \
[ \"\$(cat \$i/operstate 2>/dev/null)\" = up ] && echo \"NET|\$n\"; done"

POLL_CMD="awk '\$3 ~ /^(nvme[0-9]+n[0-9]+|sd[a-z]+)\$/ {print \"IO \"\$3\" \"\$6*512\" \"\$10*512}' /proc/diskstats; \
awk 'NR>2 {sub(/:/,\"\"); if (\$1 != \"lo\") print \"NET \"\$1\" \"\$2\" \"\$10}' /proc/net/dev; \
for h in /sys/class/hwmon/hwmon*; do n=\$(cat \$h/name 2>/dev/null); \
p=\$(basename \$(readlink -f \$h/device 2>/dev/null)); t=\$(cat \$h/temp1_input 2>/dev/null); \
[ -n \"\$n\" ] && [ -n \"\$t\" ] && echo \"TEMP|\$n|\$p|\$t\"; done"

enum_out=$(bash -c "$ENUM_CMD"; true)
poll_out=$(bash -c "$POLL_CMD"; true)

fails=0

# Modelo de CPU en la primera línea
head -1 <<<"$enum_out" | grep -q "Ryzen\|Intel\|AMD\|processor" || { echo "FALLO: modelo de CPU"; fails=1; }

# Al menos un disco y sin discos extraíbles (sdc/USB) ni zram
disk_lines=$(grep -c '^DISK|' <<<"$enum_out")
[ "$disk_lines" -ge 1 ] || { echo "FALLO: sin discos"; fails=1; }
if grep -q '^DISK|sdc|' <<<"$enum_out"; then echo "FALLO: USB incluido"; fails=1; fi
if grep -q '^DISK|zram' <<<"$enum_out"; then echo "FALLO: zram incluido"; fails=1; fi
grep '^DISK|' <<<"$enum_out" | cut -d'|' -f4 | while read -r c; do
	case "$c" in nvme[0-9]) ;; 0:0:0:0|2:0:0:0) ;; *) echo "FALLO: ctrl inesperado '$c'"; exit 1 ;; esac
done || fails=1

# Poll: IO con 3 campos numéricos y TEMP con k10temp y al menos un nvme
grep -qE '^IO (nvme[0-9]+n[0-9]+|sd[a-z]+) [0-9]+ [0-9]+$' <<<"$poll_out" || { echo "FALLO: líneas IO"; fails=1; }
grep -qE '^NET [^ ]+ [0-9]+ [0-9]+$' <<<"$poll_out" || { echo "FALLO: líneas NET"; fails=1; }
grep -q '^TEMP|k10temp|' <<<"$poll_out" || { echo "FALLO: sin k10temp"; fails=1; }
grep -q '^TEMP|nvme|nvme[0-9]|' <<<"$poll_out" || { echo "FALLO: sin temp nvme"; fails=1; }

# El controlador del hwmon nvme debe existir como disco enumerado
grep '^TEMP|nvme|' <<<"$poll_out" | cut -d'|' -f3 | while read -r dev; do
	grep -q "|$dev\$" <<<"$(grep '^DISK|' <<<"$enum_out")" || {
		echo "FALLO: hwmon '$dev' sin disco asociado"; exit 1; }
done || fails=1

[ "$fails" -eq 0 ] && echo "OK: $(grep -c '^DISK|' <<<"$enum_out") discos, $(grep -c '^NET|' <<<"$enum_out") iface(s) activas, poll correcto"
exit "$fails"
