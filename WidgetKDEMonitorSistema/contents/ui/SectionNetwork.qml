import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja Network: por interfaz — badge de iface, gráfica,
// totales de sesión (↓/↑) y leyenda con cuadraditos y valores en vivo.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: Qt.rgba(15 / 255, 17 / 255, 21 / 255, 0.72)
	border.color: Qt.rgba(1, 1, 1, 0.08)
	border.width: 1

	readonly property color downColor: "#22aaff"
	readonly property color upColor: "#ff9933"
	readonly property int cellCount: monitorRoot ? Math.max(1, monitorRoot.nets.count) : 1

	PlasmaComponents3.Label {
		id: title
		anchors.top: parent.top
		anchors.topMargin: Kirigami.Units.gridUnit * 0.4
		anchors.horizontalCenter: parent.horizontalCenter
		text: i18n("Network")
		color: "#ffffff"
		font.bold: true
		font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.85)
	}

	Item {
		id: cells
		anchors.top: title.bottom
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: Kirigami.Units.gridUnit * 0.4

		Repeater {
			model: card.monitorRoot ? card.monitorRoot.nets : []

			Item {
				id: cell
				required property int index
				required property string iface
				required property real down
				required property real up
				required property real totalDown
				required property real totalUp

				x: parent.width * cell.index / card.cellCount
				width: parent.width / card.cellCount
				height: parent.height

				Rectangle {
					visible: cell.index > 0
					x: 0
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					width: 1
					color: Qt.rgba(1, 1, 1, 0.15)
				}

				// Contenido en columna: badge, gráfica, totales, leyenda
				ColumnLayout {
					anchors.fill: parent
					anchors.leftMargin: cell.index > 0 ? Kirigami.Units.largeSpacing : 0
					anchors.rightMargin: Kirigami.Units.gridUnit * 0.4
					spacing: 3

					// Badge de interfaz (nombre pequeño y discreto)
					PlasmaComponents3.Label {
						text: cell.iface
						color: "#ffffff"
						opacity: 0.5
						font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.62)
					}

					LineGraph {
						id: netGraph
						Layout.fillWidth: true
						Layout.fillHeight: true
						series: [
							{ color: card.downColor, fill: true, values: [] },
							{ color: card.upColor, fill: true, values: [] }
						]
					}

					// Totales de sesión: ↓ a la izquierda, ↑ a la derecha
					RowLayout {
						Layout.fillWidth: true
						spacing: Kirigami.Units.smallSpacing

						PlasmaComponents3.Label {
							text: "↓ " + (card.monitorRoot ? card.monitorRoot.fmtBytes(cell.totalDown) : "")
							color: card.downColor
							opacity: 0.8
							font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.62)
						}
						Item { Layout.fillWidth: true }
						PlasmaComponents3.Label {
							text: "↑ " + (card.monitorRoot ? card.monitorRoot.fmtBytes(cell.totalUp) : "")
							color: card.upColor
							opacity: 0.8
							font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.62)
						}
					}

					// Leyenda con valores en vivo (cuadradito + nombre + valor)
					RowLayout {
						Layout.fillWidth: true
						spacing: Kirigami.Units.smallSpacing

						Rectangle {
							width: Kirigami.Units.gridUnit * 0.45
							height: Kirigami.Units.gridUnit * 0.45
							radius: 2
							color: card.downColor
						}
						PlasmaComponents3.Label {
							text: i18n("Download")
							color: "#ffffff"
							opacity: 0.7
							font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.62)
						}
						PlasmaComponents3.Label {
							text: card.monitorRoot ? card.monitorRoot.fmtBytes(cell.down) + "/s" : ""
							color: card.downColor
							font.bold: true
							font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
						}

						Item { Layout.fillWidth: true }

						PlasmaComponents3.Label {
							text: card.monitorRoot ? card.monitorRoot.fmtBytes(cell.up) + "/s" : ""
							color: card.upColor
							font.bold: true
							font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
						}
						PlasmaComponents3.Label {
							text: i18n("Upload")
							color: "#ffffff"
							opacity: 0.7
							font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.62)
						}
						Rectangle {
							width: Kirigami.Units.gridUnit * 0.45
							height: Kirigami.Units.gridUnit * 0.45
							radius: 2
							color: card.upColor
						}
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
			visible: !card.monitorRoot || card.monitorRoot.nets.count === 0
			anchors.centerIn: parent
			text: i18n("Sin conexión")
			color: "#ffffff"
			opacity: 0.5
		}
	}
}
