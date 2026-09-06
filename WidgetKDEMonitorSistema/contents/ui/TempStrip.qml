import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Barra vertical de temperatura pegada al lateral de la caja de GPU/CPU.
// Escala fija 0-105 °C y color según tramo; si no llega dato (0) se muestra vacía.
// Item con anclajes en vez de layout anidado: así el ancho lo manda siempre
// quien lo instancia y no puede hincharse.
Item {
	id: strip

	property real temp: 0
	property string title: ""
	property bool showTitle: true

	implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.3)

	PlasmaComponents3.Label {
		id: titleLabel
		visible: strip.showTitle
		anchors.top: parent.top
		anchors.horizontalCenter: parent.horizontalCenter
		text: strip.title
		font: Kirigami.Theme.smallFont
		color: Kirigami.Theme.textColor
		opacity: 0.55
	}

	Rectangle {
		id: groove
		anchors.top: titleLabel.visible ? titleLabel.bottom : parent.top
		anchors.topMargin: Kirigami.Units.smallSpacing
		anchors.bottom: valueLabel.top
		anchors.bottomMargin: Kirigami.Units.smallSpacing
		anchors.left: parent.left
		anchors.right: parent.right
		radius: width / 2
		color: Qt.rgba(1, 1, 1, 0.10)

		Rectangle {
			anchors.bottom: parent.bottom
			anchors.horizontalCenter: parent.horizontalCenter
			width: parent.width
			height: Math.max(0, Math.min(1, strip.temp / 105)) * parent.height
			radius: width / 2
			color: strip.tempColor(strip.temp)
		}
	}

	PlasmaComponents3.Label {
		id: valueLabel
		anchors.bottom: parent.bottom
		anchors.horizontalCenter: parent.horizontalCenter
		text: strip.temp > 0 ? Math.round(strip.temp) + "°" : "—"
		font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
		font.bold: true
		color: strip.tempColor(strip.temp)
	}

	function tempColor(t) {
		return t >= 75 ? "#ff5555" : t >= 55 ? "#ffb02e" : "#2ee6a8"
	}
}
