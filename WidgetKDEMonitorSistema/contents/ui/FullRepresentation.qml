import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Panel completo con posiciones deterministas (patrón Glassy: Item raíz y
// anclas, sin layouts anidados que se pisen entre sí).
//
//   [ GPU ][|T|]      [ CPU ][|T|]     <- fila 1, parejas pegadas
//   [ Disk IO ...................... ] <- fila 2, columnas por disco
//   [ Network ...................... ] <- fila 3, columnas por interfaz
Item {
	id: panel

	property var monitorRoot

	readonly property int gap: Math.round(Kirigami.Units.gridUnit * 0.6)

	SectionGpu {
		id: gpuCard
		anchors.top: panel.top
		anchors.left: panel.left
		width: panel.width * 0.48
		height: panel.height * 0.46
		monitorRoot: panel.monitorRoot
	}

	TempStrip {
		title: i18n("Temp")
		temp: panel.monitorRoot ? panel.monitorRoot.gpuTemp : 0
		anchors.top: gpuCard.top
		anchors.bottom: gpuCard.bottom
		anchors.left: gpuCard.right
		anchors.leftMargin: 2
		width: Kirigami.Units.gridUnit * 1.3
	}

	SectionCpu {
		id: cpuCard
		anchors.top: panel.top
		anchors.right: panel.right
		width: panel.width * 0.48
		height: panel.height * 0.46
		monitorRoot: panel.monitorRoot
	}

	TempStrip {
		title: i18n("Temp")
		temp: panel.monitorRoot ? panel.monitorRoot.cpuTemp : 0
		anchors.top: cpuCard.top
		anchors.bottom: cpuCard.bottom
		anchors.left: cpuCard.right
		anchors.leftMargin: 2
		width: Kirigami.Units.gridUnit * 1.3
	}

	SectionDisks {
		id: disksCard
		anchors.top: gpuCard.bottom
		anchors.topMargin: panel.gap
		anchors.left: panel.left
		anchors.right: panel.right
		height: panel.height * 0.27
		monitorRoot: panel.monitorRoot
	}

	SectionNetwork {
		id: netCard
		anchors.top: disksCard.bottom
		anchors.topMargin: panel.gap
		anchors.left: panel.left
		anchors.right: panel.right
		anchors.bottom: panel.bottom
		monitorRoot: panel.monitorRoot
	}
}
