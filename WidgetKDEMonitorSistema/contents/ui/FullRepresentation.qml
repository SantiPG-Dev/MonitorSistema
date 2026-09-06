import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Panel completo con posiciones deterministas (patrón Glassy: Item raíz y
// anclas, sin layouts anidados que se pisen entre sí).
//
//   [ GPU (temp dentro) ]  [ CPU (temp dentro) ]   <- fila 1, tarjetas completas
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
		width: panel.width * 0.49
		height: panel.height * 0.46
		monitorRoot: panel.monitorRoot
	}

	SectionCpu {
		id: cpuCard
		anchors.top: panel.top
		anchors.right: panel.right
		width: panel.width * 0.49
		height: panel.height * 0.46
		monitorRoot: panel.monitorRoot
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
