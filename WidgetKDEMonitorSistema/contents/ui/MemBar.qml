import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Barra de memoria (VRAM/RAM) al estilo de la captura: texto centrado encima.
Item {
	id: bar

	property double used: 0
	property double total: 0
	property color barColor: "#ff9a3d"
	property var fmt: function(v) { return "" }

	implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.1)

	Rectangle {
		anchors.fill: parent
		radius: height / 2
		color: Qt.rgba(1, 1, 1, 0.12)
	}

	Rectangle {
		anchors.left: parent.left
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		width: Math.max(height, parent.width * Math.min(1, bar.total > 0 ? bar.used / bar.total : 0))
		radius: height / 2
		color: bar.barColor
		opacity: 0.9
	}

	PlasmaComponents3.Label {
		anchors.centerIn: parent
		text: bar.fmt(bar.used) + " / " + bar.fmt(bar.total)
		font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
		font.bold: true
		color: "#ffffff"
	}
}
