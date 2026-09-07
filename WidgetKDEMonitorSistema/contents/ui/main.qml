import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQml
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami

PlasmoidItem {
	id: root

	// --- Estado expuesto a las secciones ---
	property string cpuModel: ""
	property real cpuUsage: 0
	property real cpuFreq: 0
	property real cpuTemp: 0          // k10temp vía hwmon
	property real ramUsed: 0
	property real ramTotal: 0
	property string gpuName: ""
	property real gpuUsage: 0
	property real gpuTemp: 0
	property real gpuFreq: 0
	property real vramUsed: 0
	property real vramTotal: 0

	// Unidades dinámicas: discos (nvme/sd fijos, sin USB ni zram) e interfaces up
	property ListModel disks: ListModel { dynamicRoles: true }
	property ListModel nets: ListModel { dynamicRoles: true }

	Plasmoid.title: i18n("Monitor del sistema")
	Plasmoid.icon: "utilities-system-monitor"

	// Las cajas dibujan su propio fondo; sin esto Plasma pintaría otro debajo
	Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

	// Tamaño en el escritorio (en la raíz del PlasmoidItem)
	Layout.minimumWidth: Kirigami.Units.gridUnit * 40
	Layout.minimumHeight: Kirigami.Units.gridUnit * 30
	Layout.preferredWidth: Kirigami.Units.gridUnit * 46
	Layout.preferredHeight: Kirigami.Units.gridUnit * 34

	// Widget de escritorio: siempre la representación completa
	preferredRepresentation: fullRepresentation
	fullRepresentation: FullRepresentation {
		monitorRoot: root
	}

	// --- Sensores fijos de ksystemstats (GPU vía NVML, CPU y RAM) ---
	Sensors.Sensor {
		sensorId: "gpu/gpu0/name"
		onValueChanged: root.gpuName = String(value ?? "")
	}
	Sensors.Sensor {
		sensorId: "gpu/gpu0/usage"
		onValueChanged: root.gpuUsage = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "gpu/gpu0/temperature"
		onValueChanged: root.gpuTemp = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "gpu/gpu0/coreFrequency"
		onValueChanged: root.gpuFreq = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "gpu/gpu0/usedVram"
		onValueChanged: root.vramUsed = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "gpu/gpu0/totalVram"
		onValueChanged: root.vramTotal = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "cpu/all/usage"
		onValueChanged: root.cpuUsage = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "cpu/all/averageFrequency"
		onValueChanged: root.cpuFreq = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "memory/physical/used"
		onValueChanged: root.ramUsed = Number(value) || 0
	}
	Sensors.Sensor {
		sensorId: "memory/physical/total"
		onValueChanged: root.ramTotal = Number(value) || 0
	}

	// --- Comandos del motor "executable" ---
	// Enumeración inicial: modelo de CPU, discos fijos e interfaces activas.
	// Ojo: se detecta una sola vez al cargar; un disco o red nueva requiere recargar el widget.
	readonly property string enumCmd:
		"grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //'; " +
		"for d in /sys/block/*; do n=${d##*/}; case $n in nvme[0-9]*n[0-9]*|sd[a-z]*) " +
		"[ \"$(cat $d/removable 2>/dev/null)\" = 0 ] || continue; " +
		"m=$(cat $d/device/model 2>/dev/null | tr -s ' ' | sed 's/^ //;s/ $//'); " +
		"c=$(basename $(readlink -f $d/device)); echo \"DISK|$n|$m|$c\";; esac; done; " +
		"for i in /sys/class/net/*; do n=${i##*/}; [ \"$n\" != lo ] && " +
		"[ \"$(cat $i/operstate 2>/dev/null)\" = up ] && echo \"NET|$n\"; done"

	// Poll periódico: IO por disco acumulado, tráfico por interfaz acumulado y temps hwmon.
	// La primera línea es la epoch-ms en el momento de leer los contadores: así el dt de las
	// tasas no hereda el retardo de spawn del shell ni la entrega a QML.
	// Límite asumido: solo temp1 del hwmon (Composite en NVMe, Tctl en k10temp); si algún
	// disco expusiera más sensores habría que iterar temp*_input.
	readonly property string pollCmd:
		"date +%s%3N; " +
		"awk '$3 ~ /^(nvme[0-9]+n[0-9]+|sd[a-z]+)$/ {print \"IO \"$3\" \"$6*512\" \"$10*512}' /proc/diskstats; " +
		"awk 'NR>2 {sub(/:/,\"\"); if ($1 != \"lo\") print \"NET \"$1\" \"$2\" \"$10}' /proc/net/dev; " +
		"for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null); " +
		"p=$(basename $(readlink -f $h/device 2>/dev/null)); t=$(cat $h/temp1_input 2>/dev/null); " +
		"[ -n \"$n\" ] && [ -n \"$t\" ] && echo \"TEMP|$n|$p|$t\"; done"

	// Acumulados del poll anterior para calcular tasas de IO de disco
	property var lastIO: ({})
	property double lastTick: 0

	// Tasas de red por interfaz vía ksystemstats (sensor download/upload en
	// bytes/s), como el widget Glassy. Se crean al enumerar cada interfaz.
	Component {
		id: netRateSensor
		Sensors.Sensor {
			property string ifc: ""
			property bool isDown: true
			onValueChanged: {
				var v = Number(value)
				if (!isFinite(v) || v < 0) return
				root.setNetRow(ifc, isDown ? { down: v } : { up: v })
			}
		}
	}
	property var netSensors: []

	function makeNetSensor(ifc, isDown) {
		var s = netRateSensor.createObject(root, {
			ifc: ifc, isDown: isDown,
			sensorId: "network/" + ifc + (isDown ? "/download" : "/upload")
		})
		if (s) netSensors.push(s)
	}

	// Enumeración: conexión puntual, se desconecta al recibir la salida
	Plasma5Support.DataSource {
		id: enumSource
		engine: "executable"
		connectedSources: []
		onNewData: (sourceName, data) => {
			root.parseEnum(String(data["stdout"] ?? ""))
			enumSource.disconnectSource(sourceName)
		}
	}

	// Poll periódico: 1 s para que la red se mida por segundo como los widgets nativos.
	// El intervalo va en la propiedad del DataSource, connectSource() solo acepta el comando
	Plasma5Support.DataSource {
		id: pollSource
		engine: "executable"
		interval: 1000
		connectedSources: [root.pollCmd]
		onNewData: (sourceName, data) => {
			root.parsePoll(String(data["stdout"] ?? ""))
		}
	}

	Component.onCompleted: {
		enumSource.connectSource(enumCmd)
	}

	// --- Parseo de la enumeración inicial ---
	function parseEnum(out) {
		var lines = out.split("\n")
		for (var i = 0; i < lines.length; i++) {
			var l = lines[i]
			if (!l) continue
			if (l.indexOf("DISK|") === 0) {
				var dp = l.split("|")
				disks.append({ name: dp[1], diskModel: dp[2] || "", ctrl: dp[3] || "",
					temp: -1, read: 0, write: 0 })
			} else if (l.indexOf("NET|") === 0) {
				var nm = l.slice(4)
				nets.append({ iface: nm, down: 0, up: 0, totalDown: 0, totalUp: 0 })
				makeNetSensor(nm, true)
				makeNetSensor(nm, false)
			} else if (!cpuModel) {
				cpuModel = l.trim()
			}
		}
	}

	// --- Parseo del poll periódico: totales de sesión de red y IO/temps ---
	// Las tasas de red las dan los sensores; aquí solo importan los contadores
	// acumulados para los totales ↓/↑.
	function parsePoll(out) {
		var lines = out.split("\n")
		// Hora real de la lectura de contadores (epoch ms), no la de llegada a QML
		var now = Number(lines[0])
		if (!isFinite(now) || now <= 0) now = Date.now()
		var dt = lastTick > 0 ? Math.max(0.2, (now - lastTick) / 1000) : 0

		for (var i = 1; i < lines.length; i++) {
			var l = lines[i]
			if (!l) continue
			if (l.indexOf("IO ") === 0) {
				var p = l.split(" ")
				var name = p[1], rb = Number(p[2]), wb = Number(p[3])
				var prev = lastIO[name]
				setDiskRow(name, {
					read: prev && dt > 0 ? Math.max(0, (rb - prev.rb) / dt) : 0,
					write: prev && dt > 0 ? Math.max(0, (wb - prev.wb) / dt) : 0
				})
				lastIO[name] = { rb: rb, wb: wb }
			} else if (l.indexOf("NET ") === 0) {
				var q = l.split(" ")
				setNetRow(q[1], { totalDown: Number(q[2]), totalUp: Number(q[3]) })
			} else if (l.indexOf("TEMP|") === 0) {
				var t = l.split("|")
				var chip = t[1], dev = t[2], milli = Number(t[3])
				if (!isFinite(milli)) continue
				var deg = milli / 1000
				if (chip === "k10temp") {
					cpuTemp = deg
				} else if (chip === "nvme") {
					// el device del hwmon es el controlador nvmeX, igual que en /sys/block
					for (var d = 0; d < disks.count; d++) {
						if (disks.get(d).ctrl === dev) {
							disks.setProperty(d, "temp", deg)
							break
						}
					}
				}
			}
		}
		lastTick = now
	}

	function setDiskRow(name, fields) {
		for (var i = 0; i < disks.count; i++) {
			if (disks.get(i).name === name) {
				disks.setProperty(i, "read", fields.read)
				disks.setProperty(i, "write", fields.write)
				return
			}
		}
	}

	function setNetRow(ifc, fields) {
		for (var i = 0; i < nets.count; i++) {
			if (nets.get(i).iface === ifc) {
				for (var k in fields) nets.setProperty(i, k, fields[k])
				return
			}
		}
	}

	// --- Formateadores (mismos criterios que los widgets nativos) ---
	function fmtBytes(v) {
		v = Number(v) || 0
		var units = ["B", "KiB", "MiB", "GiB", "TiB"]
		var i = 0
		while (v >= 1024 && i < units.length - 1) { v /= 1024; i++ }
		var dec = v >= 100 ? 0 : v >= 10 ? 1 : 2
		return v.toFixed(dec) + " " + units[i]
	}

	function fmtPercent(v) {
		v = Number(v) || 0
		return v.toFixed(1) + "%"
	}
}
