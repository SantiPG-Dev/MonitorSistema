import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// Caja Network: como la captura (descarga/subida con totales) y una columna
// por cada interfaz activa encontrada.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: "rgba(15,17,21,0.72)"
	border.color: "rgba(255,255,255,0.08)"
	border.width: 1

	readonly property color downColor: "#3fb9ff"
	readonly property color upColor: "#ff9a3d"

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: Kirigami.Units.gridUnit * 0.6
		spacing: Kirigami.Units.smallSpacing

		PlasmaComponents3.Label {
			Layout.alignment: Qt.AlignHCenter
			text: i18n("Network")
			font.bold: true
			font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.9)
			color: "#ffffff"
		}

		RowLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: 0

			Repeater {
				model: monitorRoot ? monitorRoot.nets : []

				RowLayout {
					id: netPair
					required property string iface
					required property real down
					required property real up
					required property real totalDown
					required property real totalUp
					Layout.fillWidth: true
					Layout.fillHeight: true
					spacing: 0

					Rectangle {
						visible: index > 0
						Layout.fillHeight: true
						Layout.preferredWidth: 1
						Layout.topMargin: Kirigami.Units.smallSpacing
						Layout.bottomMargin: Kirigami.Units.smallSpacing
						color: "rgba(255,255,255,0.15)"
					}

					ColumnLayout {
						Layout.fillWidth: true
						Layout.fillHeight: true
						Layout.leftMargin: index > 0 ? Kirigami.Units.largeSpacing : 0
						Layout.rightMargin: Kirigami.Units.largeSpacing
						spacing: 0

						RowLayout {
							Layout.fillWidth: true

							PlasmaCore.IconItem {
								Layout.preferredWidth: Kirigami.Units.gridUnit * 0.8
								Layout.preferredHeight: Kirigami.Units.gridUnit * 0.8
								source: "network-wired"
							}

							PlasmaComponents3.Label {
								text: netPair.iface
								font: Kirigami.Theme.smallFont
								font.bold: true
								color: "#ffffff"
							}

							Item { Layout.fillWidth: true }
						}

						RowLayout {
							Layout.fillWidth: true

							// Descarga: velocidad grande + total acumulado
							ColumnLayout {
								Layout.fillWidth: true
								spacing: 0

								PlasmaComponents3.Label {
									text: "▼ " + (monitorRoot ? monitorRoot.fmtBytes(netPair.down) + "/s" : "")
									font.bold: true
									font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.95)
									color: card.downColor
								}

								PlasmaComponents3.Label {
									text: monitorRoot ? monitorRoot.fmtBytes(netPair.totalDown) : ""
									font: Kirigami.Theme.smallFont
									opacity: 0.55
									color: "#ffffff"
								}
							}

							// Subida
							ColumnLayout {
								Layout.fillWidth: true
								spacing: 0

								PlasmaComponents3.Label {
									Layout.alignment: Qt.AlignRight
									text: "▲ " + (monitorRoot ? monitorRoot.fmtBytes(netPair.up) + "/s" : "")
									font.bold: true
									font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.95)
									color: card.upColor
								}

								PlasmaComponents3.Label {
									Layout.alignment: Qt.AlignRight
									text: monitorRoot ? monitorRoot.fmtBytes(netPair.totalUp) : ""
									font: Kirigami.Theme.smallFont
									opacity: 0.55
									color: "#ffffff"
								}
							}
						}

						LineGraph {
							id: netGraph
							Layout.fillWidth: true
							Layout.fillHeight: true
							series: [
								{ color: card.downColor, fill: false, values: [] },
								{ color: card.upColor, fill: false, values: [] }
							]
						}
					}

					onDownChanged: netGraph.push(0, down)
					onUpChanged: netGraph.push(1, up)
					Component.onCompleted: {
						netGraph.push(0, 0)
						netGraph.push(1, 0)
					}
				}
			}

			PlasmaComponents3.Label {
				visible: !monitorRoot || monitorRoot.nets.count === 0
				Layout.fillWidth: true
				Layout.fillHeight: true
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				text: i18n("Sin conexión")
				opacity: 0.5
				color: "#ffffff"
			}
		}
	}
}
