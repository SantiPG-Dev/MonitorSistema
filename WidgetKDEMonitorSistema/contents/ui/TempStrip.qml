import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Barra vertical de temperatura pegada al lateral de la caja de GPU/CPU.
// Escala fija 0-105 °C y color según tramo; si no llega dato (0) se muestra vacía.
ColumnLayout {
	id: strip

	property real temp: 0
	property string title: ""

	spacing: Kirigami.Units.smallSpacing

	PlasmaComponents3.Label {
		Layout.alignment: Qt.AlignHCenter
		text: strip.title
		font: Kirigami.Theme.smallFont
		color: Kirigami.Theme.textColor
		opacity: 0.55
	}

	Rectangle {
		Layout.fillWidth: true
		Layout.fillHeight: true
		radius: width / 2
		color: "rgba(255,255,255,0.10)"

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
		Layout.alignment: Qt.AlignHCenter
		text: strip.temp > 0 ? Math.round(strip.temp) + "°" : "—"
		font: Kirigami.Theme.smallFont
		font.bold: true
		color: strip.tempColor(strip.temp)
	}

	function tempColor(t) {
		return t >= 75 ? "#ff5555" : t >= 55 ? "#ffb02e" : "#2ee6a8"
	}
}
