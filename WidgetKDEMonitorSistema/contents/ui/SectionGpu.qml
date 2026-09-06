import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja GPU con la temperatura DENTRO, como una unidad: gráfica a la izquierda,
// barra de temperatura pegada al borde derecho separada por una línea sutil.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: Qt.rgba(15 / 255, 17 / 255, 21 / 255, 0.72)
	border.color: Qt.rgba(1, 1, 1, 0.08)
	border.width: 1

	readonly property color lineColor: "#ff9a3d"
	readonly property int baseFont: Math.round(Kirigami.Units.gridUnit * 0.7)

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: Kirigami.Units.gridUnit * 0.5
		spacing: Kirigami.Units.smallSpacing

		// Cabecera: [NVIDIA + modelo ...... ]
		PlasmaComponents3.Label {
			Layout.fillWidth: true
			elide: Text.ElideRight
			textFormat: Text.RichText
			text: "<div style='white-space: nowrap'>" +
				"<span style='color:#76b900;font-weight:bold'>NVIDIA</span>" +
				"<span style='color:#ffffff'> " +
				(monitorRoot ? monitorRoot.gpuName.replace(/^NVIDIA\s*/, "") : "") +
				"</span></div>"
			font.pixelSize: card.baseFont
		}

		// Cuerpo: gráfica + overlay de valores + columna de temperatura
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
				temp: monitorRoot ? monitorRoot.gpuTemp : 0
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

				// Valores ENCIMA de la gráfica (declarados después del canvas)
				PlasmaComponents3.Label {
					anchors.top: parent.top
					anchors.horizontalCenter: parent.horizontalCenter
					text: i18n("GPU")
					color: "#ffffff"
					font.bold: true
					font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.85)
				}

				ColumnLayout {
					anchors.top: parent.top
					anchors.right: parent.right
					spacing: 0

					PlasmaComponents3.Label {
						Layout.alignment: Qt.AlignRight
						text: monitorRoot ? monitorRoot.fmtPercent(monitorRoot.gpuUsage) : "0%"
						color: card.lineColor
						font.bold: true
						font.pixelSize: Math.round(Kirigami.Units.gridUnit * 1.4)
					}

					PlasmaComponents3.Label {
						Layout.alignment: Qt.AlignRight
						visible: monitorRoot && monitorRoot.gpuFreq > 0
						text: monitorRoot && monitorRoot.gpuFreq > 0 ? Math.round(monitorRoot.gpuFreq) + " MHz" : ""
						color: "#ffffff"
						opacity: 0.55
						font.pixelSize: card.baseFont
					}
				}
			}
		}

		MemBar {
			Layout.fillWidth: true
			used: monitorRoot ? monitorRoot.vramUsed : 0
			total: monitorRoot ? monitorRoot.vramTotal : 0
			barColor: card.lineColor
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
				text: i18n("GPU")
				color: "#ffffff"
				opacity: 0.6
				font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.6)
			}
		}
	}

	Connections {
		target: monitorRoot
		ignoreUnknownSignals: true
		function onGpuUsageChanged() {
			usageGraph.push(0, monitorRoot.gpuUsage)
		}
	}
}
