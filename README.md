# 🖥️ Monitor Sistema — Widget para KDE Plasma 6

Monitor completo del sistema **en un solo widget**, con el estilo de los widgets de sensor nativos (fondo oscuro, líneas de colores, valor grande superpuesto).

![Plasma 6](https://img.shields.io/badge/Plasma-6-blue) ![License](https://img.shields.io/badge/license-GPL--3.0%2B-green)

---

## ✨ Qué muestra

| Sección | Contenido |
| --- | --- |
| **GPU + Temp** | Uso con historial en línea y **relleno en degradado**, frecuencia, modelo junto a NVIDIA, barra de VRAM. Barra vertical de temperatura pegada a la caja |
| **CPU + Temp** | Uso con historial en línea y degradado, frecuencia, barra de **RAM del sistema**, modelo de procesador. Barra vertical de temperatura pegada |
| **Disk IO** | Una columna por disco fijo (NVMe + HDD, sin USB/zram) separadas por línea vertical: lectura (cian), escritura (naranja) y **temperatura en rojo** cuando el disco tiene sensor |
| **Network** | Una columna por interfaz activa: bajada/subida con velocidad y total acumulado |

Si solo hay un disco o una conexión, su columna ocupa todo el ancho; si hay varios, se reparten el espacio a partes iguales.

## 📋 Fuentes de datos

- **ksystemstats** (vía `org.kde.ksysguard.sensors`): GPU completa (NVML), uso/frecuencia de CPU, RAM física.
- **`/proc` y `sysfs`** (poll cada 2 s): IO por disco, tráfico por interfaz, temperaturas NVMe y CPU (k10temp).

## ⚠️ Límites conocidos

- Los HDD sin SMART activado no exponen temperatura: simplemente no se muestra en rojo. Para activarla: `sudo smartctl -s on /dev/sdX` (habría que añadir la lectura vía udisks).
- El plugin NVML de ksystemstats no expone decode/encode de GPU, así que la leyenda solo muestra la serie de uso.
- Discos e interfaces se detectan al cargar el widget; uno nuevo requiere recargarlo.
- Las series de decode/encode y swap de los widgets nativos no aplican aquí por diseño (boceto del PDF).

## 📥 Instalación

```bash
git clone <este-repo>
kpackagetool6 --type=Plasma/Applet --install WidgetKDEMonitorSistema
```

Actualizar tras cambiar código:

```bash
kpackagetool6 --type=Plasma/Applet --upgrade WidgetKDEMonitorSistema
```

Después: clic derecho en el escritorio → *Añadir widgets* → **Monitor Sistema**.

## 🧪 Selfcheck

```bash
./selfcheck.sh
```

Ejecuta los mismos comandos de datos que usa el widget y valida que el formato de salida es el esperado.
