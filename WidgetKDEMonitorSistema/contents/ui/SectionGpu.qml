import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja GPU: igual que la captura (uso grande, frecuencia, VRAM) pero con el
// historial en línea con relleno en degradado y el modelo junto a NVIDIA.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: "rgba(15,17,21,0.72)"
	border.color: "rgba(255,255,255,0.08)"
	border.width: 1

	readonly property color lineColor: "#ff9a3d"

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: Kirigami.Units.gridUnit * 0.6
		spacing: Kirigami.Units.smallSpacing

		// Cabecera: modelo a la izquierda, título centrado encima
		Item {
			Layout.fillWidth: true
			implicitHeight: brandLabel.implicitHeight

			PlasmaComponents3.Label {
				id: brandLabel
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width - Kirigami.Units.gridUnit * 3
				elide: Text.ElideRight
				textFormat: Text.RichText
				text: "<div style='white-space: nowrap'>" +
					"<span style='color:#76b900;font-weight:bold'>NVIDIA</span>" +
					"<span style='color:" + Kirigami.Theme.textColor + "'> " +
					(monitorRoot ? monitorRoot.gpuName.replace(/^NVIDIA\s*/, "") : "") +
					"</span></div>"
				font: Kirigami.Theme.smallFont
			}

			PlasmaComponents3.Label {
				anchors.centerIn: parent
				text: i18n("GPU")
				font.bold: true
				font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.9)
				color: "#ffffff"
			}
		}

		// Historial de uso con degradado + valor actual y frecuencia superpuestos
		Item {
			Layout.fillWidth: true
			Layout.fillHeight: true

			LineGraph {
				id: usageGraph
				anchors.fill: parent
				percent: true
				series: [ { color: card.lineColor, fill: true, values: [] } ]
			}

			ColumnLayout {
				anchors.top: parent.top
				anchors.right: parent.right
				anchors.margins: Kirigami.Units.smallSpacing
				spacing: 0

				PlasmaComponents3.Label {
					Layout.alignment: Qt.AlignRight
					text: monitorRoot ? monitorRoot.fmtPercent(monitorRoot.gpuUsage) : "0%"
					font.pixelSize: Math.round(Kirigami.Units.gridUnit * 1.6)
					font.bold: true
					color: card.lineColor
				}

				PlasmaComponents3.Label {
					Layout.alignment: Qt.AlignRight
					text: monitorRoot && monitorRoot.gpuFreq > 0 ? Math.round(monitorRoot.gpuFreq) + " MHz" : ""
					font: Kirigami.Theme.smallFont
					opacity: 0.6
					color: "#ffffff"
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

		// Leyenda: el plugin de NVML no expone decode/encode, solo la serie de uso
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
				font: Kirigami.Theme.smallFont
				opacity: 0.6
				color: "#ffffff"
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
