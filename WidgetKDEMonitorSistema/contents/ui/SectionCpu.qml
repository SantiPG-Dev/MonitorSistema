import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja CPU con la temperatura DENTRO, como una unidad (igual que GPU):
// gráfica a la izquierda, barra de temperatura pegada al borde derecho.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: Qt.rgba(15 / 255, 17 / 255, 21 / 255, 0.72)
	border.color: Qt.rgba(1, 1, 1, 0.08)
	border.width: 1

	readonly property color lineColor: "#2ee6a8"
	readonly property int baseFont: Math.round(Kirigami.Units.gridUnit * 0.7)

	function brandAndModel() {
		var m = monitorRoot ? monitorRoot.cpuModel : ""
		if (!m) return { brand: "", model: "" }
		var sp = m.indexOf(" ")
		return sp > 0
			? { brand: m.substr(0, sp), model: m.substr(sp + 1) }
			: { brand: m, model: "" }
	}

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: Kirigami.Units.gridUnit * 0.5
		spacing: Kirigami.Units.smallSpacing

		// Título de la tarjeta
		PlasmaComponents3.Label {
			Layout.alignment: Qt.AlignHCenter
			text: i18n("CPU")
			color: "#ffffff"
			font.bold: true
			font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.85)
		}

		// Marca y modelo
		PlasmaComponents3.Label {
			Layout.fillWidth: true
			elide: Text.ElideRight
			textFormat: Text.RichText
			text: {
				var bm = brandAndModel()
				return "<div style='white-space: nowrap'>" +
					"<span style='color:#ff4b4b;font-weight:bold'>" + bm.brand + "</span>" +
					"<span style='color:#ffffff'> " + bm.model + "</span></div>"
			}
			font.pixelSize: card.baseFont
		}

		Item {
			Layout.fillWidth: true
			Layout.fillHeight: true

			Rectangle {
				id: stripSep
				anchors.right: tempZone.left
				anchors.rightMargin: Kirigami.Units.smallSpacing
				anchors.top: parent.top
				anchors.bottom: parent.bottom
				width: 1
				color: Qt.rgba(1, 1, 1, 0.12)
			}

			TempStrip {
				id: tempZone
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.bottom: parent.bottom
				width: Kirigami.Units.gridUnit * 1.3
				showTitle: false
				temp: monitorRoot ? monitorRoot.cpuTemp : 0
			}

			Item {
				id: graphZone
				anchors.top: parent.top
				anchors.bottom: parent.bottom
				anchors.left: parent.left
				anchors.right: stripSep.left
				anchors.rightMargin: Kirigami.Units.smallSpacing

				LineGraph {
					id: usageGraph
					anchors.fill: parent
					percent: true
					series: [ { color: card.lineColor, fill: true, values: [] } ]
				}

				ColumnLayout {
					anchors.top: parent.top
					anchors.right: parent.right
					spacing: 0

					PlasmaComponents3.Label {
						Layout.alignment: Qt.AlignRight
						text: monitorRoot ? monitorRoot.fmtPercent(monitorRoot.cpuUsage) : "0%"
						color: card.lineColor
						font.bold: true
						font.pixelSize: Math.round(Kirigami.Units.gridUnit * 1.4)
					}

					PlasmaComponents3.Label {
						Layout.alignment: Qt.AlignRight
						visible: monitorRoot && monitorRoot.cpuFreq > 0
						text: monitorRoot && monitorRoot.cpuFreq > 0 ? Math.round(monitorRoot.cpuFreq) + " MHz" : ""
						color: "#ffffff"
						opacity: 0.55
						font.pixelSize: card.baseFont
					}
				}
			}
		}

		MemBar {
			Layout.fillWidth: true
			used: monitorRoot ? monitorRoot.ramUsed : 0
			total: monitorRoot ? monitorRoot.ramTotal : 0
			barColor: "#b48ead"
			fmt: monitorRoot ? monitorRoot.fmtBytes : function(v) { return "" }
		}

		RowLayout {
			spacing: Kirigami.Units.smallSpacing

			Rectangle {
				width: Kirigami.Units.gridUnit * 0.45
				height: Kirigami.Units.gridUnit * 0.45
				radius: 2
				color: card.lineColor
			}

			PlasmaComponents3.Label {
				text: i18n("CPU")
				color: "#ffffff"
				opacity: 0.6
				font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
			}
		}
	}

	Connections {
		target: monitorRoot
		ignoreUnknownSignals: true
		function onCpuUsageChanged() {
			usageGraph.push(0, monitorRoot.cpuUsage)
		}
	}
}
