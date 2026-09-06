# 📊 Monitor Sistema — Widget para KDE Plasma 6

Monitor completo del equipo **en un solo widget** de escritorio, con el look de los widgets de sensor nativos de Plasma: tarjetas oscuras, líneas de colores, valor grande superpuesto y relleno en degradado.

![Plasma 6](https://img.shields.io/badge/Plasma-6-blue) ![QML](https://img.shields.io/badge/QML-QtQuick-orange) ![License](https://img.shields.io/badge/license-GPL--3.0%2B-green)

```
┌───────────────────────────┐ ┌───────────────────────────┐
│            GPU            │ │            CPU            │
│  NVIDIA GeForce RTX …     │ │  AMD Ryzen 5 …            │
│  ▁▂▄█▆▃▁▂▄ (degradado) ▐T│ │  ▁▂▄█▆▃▁▂▄ (degradado) ▐T│
│          VRAM            │ │           RAM             │
│  ▓▓▓▓▓▓▓▓░░░░ 12/16 GiB  │ │  ▓▓▓▓░░░░░░░░ 9/31 GiB    │
└───────────────────────────┘ └───────────────────────────┘
┌───────────────────────────────────────────────────────────┐
│                         Disk IO                           │
│  nvme0n1 50°C │ nvme1n1 46°C │ sda │ sdb                 │
│  ▂▄█▆▃▁ (R/W por disco, separador vertical cada uno)      │
├───────────────────────────────────────────────────────────┤
│                         Network                           │
│  enp6s0: ↓ 9.8 KiB/s  3.45 GiB │ ▲ 0 B/s  82.8 MiB       │
└───────────────────────────────────────────────────────────┘
```

---

## ✨ Características

| Sección | Qué muestra |
| --- | --- |
| **GPU** | Uso en gráfica de línea **con relleno en degradado**, % actual y MHz superpuestos, barra de **VRAM**, y **barra vertical de temperatura** integrada en la tarjeta, separada por una línea sutil |
| **CPU** | Lo mismo que GPU: uso con degradado, % y MHz, barra de **RAM del sistema** y temperatura integrada |
| **Disk IO** | Una columna por disco fijo (NVMe + HDD, sin USB ni zram) separadas por **línea vertical**: velocidades de lectura (cian) y escritura (ámbar), y **temperatura en rojo** en los discos que tienen sensor |
| **Network** | Una columna por interfaz activa: totales de sesión (↓/↑), leyenda con cuadraditos y velocidades en vivo |

Detalles de diseño:

- 🎨 Paleta de alto contraste sobre tarjeta oscura translúcida: naranja (GPU/subida), verde cian (CPU), cian (lectura/bajada), ámbar (escritura), púrpura (RAM), rojo (temperaturas)
- 📐 Layout determinista: fila de GPU/CPU arriba, Disk IO y Network a ancho completo repartiendo el espacio a partes iguales entre las unidades encontradas
- 🔢 Eje Y con etiquetas (0/50/100 % o autoescala en KiB/MiB/GiB por segundo) y rejilla horizontal tenue
- 🖥️ Widget de escritorio, redimensionable; ~60 muestras de historial por gráfica, refresco cada 2 s

## 📋 Fuentes de datos

- **ksystemstats** (vía `org.kde.ksysguard.sensors`): GPU completa por NVML (uso, temperatura, frecuencia, VRAM, modelo), uso/frecuencia de CPU y RAM física
- **`/proc` + `sysfs`** (poll de 2 s con el motor `executable`): IO por disco y tráfico por interfaz desde `/proc/diskstats` y `/proc/net/dev`, temperaturas NVMe y CPU (k10temp) desde `hwmon`

Discos e interfaces se detectan automáticamente al cargar el widget.

## ⚠️ Límites conocidos

- Los HDD sin SMART activado no exponen temperatura: simplemente no se muestra en rojo. Para activarla: `sudo smartctl -s on /dev/sdX` (y añadir la lectura vía udisks)
- El plugin NVML de ksystemstats no expone decode/encode de GPU, por lo que la leyenda solo muestra la serie de uso
- Un disco o interfaz conectados después de cargar el widget requieren recargarlo
- Solo se lee `temp1` de cada hwmon (Composite en NVMe, Tctl en k10temp)

## 📥 Instalación

```bash
git clone https://github.com/SantiPG-Dev/MonitorSistema.git
cd MonitorSistema
kpackagetool6 --type=Plasma/Applet --install WidgetKDEMonitorSistema
```

Actualizar tras cambiar código:

```bash
kpackagetool6 --type=Plasma/Applet --upgrade WidgetKDEMonitorSistema
```

Después: clic derecho en el escritorio → *Añadir widgets* → **Monitor Sistema**.

### 📋 Requisitos

- KDE Plasma 6 (probado en 6.7)
- `kpackagetool6` (incluido en `plasma-desktop`)
- Driver NVIDIA propietario para los datos de GPU (NVML)

## 🧪 Selfcheck

```bash
./selfcheck.sh
```

Ejecuta los mismos comandos de datos que usa el widget y valida el formato de la salida (discos detectados, interfaces activas, temperaturas y mapeo hwmon↔disco).

## 🗺️ Roadmap

- [ ] Temperatura de HDD vía udisks/SMART
- [ ] Colores configurables desde el diálogo de preferencias
- [ ] Duración del historial configurable

## 📄 Licencia

GPL-3.0+ — ver [LICENSE](LICENSE).
