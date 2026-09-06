import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja CPU: igual que GPU (línea con degradado), barra de RAM del sistema
// y el modelo de procesador en la cabecera.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: Qt.rgba(15/255, 17/255, 21/255, 0.72)
	border.color: Qt.rgba(1, 1, 1, 0.08)
	border.width: 1

	readonly property color lineColor: "#2ee6a8"

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
		anchors.margins: Kirigami.Units.gridUnit * 0.6
		spacing: Kirigami.Units.smallSpacing

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
				text: {
					var bm = brandAndModel()
					return "<div style='white-space: nowrap'>" +
						"<span style='color:#ff4b4b;font-weight:bold'>" + bm.brand + "</span>" +
						"<span style='color:" + Kirigami.Theme.textColor + "'> " + bm.model + "</span></div>"
				}
				font: Kirigami.Theme.smallFont
			}

			PlasmaComponents3.Label {
				anchors.centerIn: parent
				text: i18n("CPU")
				font.bold: true
				font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.9)
				color: "#ffffff"
			}
		}

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
					text: monitorRoot ? monitorRoot.fmtPercent(monitorRoot.cpuUsage) : "0%"
					font.pixelSize: Math.round(Kirigami.Units.gridUnit * 1.6)
					font.bold: true
					color: card.lineColor
				}

				PlasmaComponents3.Label {
					Layout.alignment: Qt.AlignRight
					text: monitorRoot && monitorRoot.cpuFreq > 0 ? Math.round(monitorRoot.cpuFreq) + " MHz" : ""
					font: Kirigami.Theme.smallFont
					opacity: 0.6
					color: "#ffffff"
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
				font: Kirigami.Theme.smallFont
				opacity: 0.6
				color: "#ffffff"
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
