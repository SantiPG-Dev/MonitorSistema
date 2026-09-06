import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja Network: título y una columna por interfaz activa con posición
// determinista (x = ancho * indice), con bajada/subida, totales y gráfica.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: Qt.rgba(15 / 255, 17 / 255, 21 / 255, 0.72)
	border.color: Qt.rgba(1, 1, 1, 0.08)
	border.width: 1

	readonly property color downColor: "#3fb9ff"
	readonly property color upColor: "#ff9a3d"
	readonly property int cellCount: monitorRoot ? Math.max(1, monitorRoot.nets.count) : 1
	readonly property int baseFont: Math.round(Kirigami.Units.gridUnit * 0.65)

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
		anchors.topMargin: Kirigami.Units.smallSpacing
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.bottomMargin: Kirigami.Units.gridUnit * 0.4

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
					anchors.topMargin: Kirigami.Units.smallSpacing
					anchors.bottom: parent.bottom
					anchors.bottomMargin: Kirigami.Units.smallSpacing
					width: 1
					color: Qt.rgba(1, 1, 1, 0.15)
				}

				PlasmaComponents3.Label {
					id: ifaceName
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.leftMargin: cell.index > 0 ? Kirigami.Units.largeSpacing : 0
					text: cell.iface
					color: "#ffffff"
					font.bold: true
					font.pixelSize: card.baseFont
				}

				// Bajada: velocidad + total acumulado
				Column {
					id: downCol
					anchors.top: ifaceName.bottom
					anchors.topMargin: Kirigami.Units.smallSpacing
					anchors.left: ifaceName.left
					spacing: 0

					PlasmaComponents3.Label {
						text: "▼ " + (card.monitorRoot ? card.monitorRoot.fmtBytes(cell.down) + "/s" : "")
						color: card.downColor
						font.bold: true
						font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.9)
					}
					PlasmaComponents3.Label {
						text: card.monitorRoot ? card.monitorRoot.fmtBytes(cell.totalDown) : ""
						color: "#ffffff"
						opacity: 0.55
						font.pixelSize: card.baseFont
					}
				}

				// Subida: velocidad + total acumulado
				Column {
					anchors.top: ifaceName.bottom
					anchors.topMargin: Kirigami.Units.smallSpacing
					anchors.right: parent.right
					anchors.rightMargin: Kirigami.Units.gridUnit * 0.5
					spacing: 0

					PlasmaComponents3.Label {
						text: "▲ " + (card.monitorRoot ? card.monitorRoot.fmtBytes(cell.up) + "/s" : "")
						color: card.upColor
						font.bold: true
						font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.9)
					}
					PlasmaComponents3.Label {
						text: card.monitorRoot ? card.monitorRoot.fmtBytes(cell.totalUp) : ""
						color: "#ffffff"
						opacity: 0.55
						font.pixelSize: card.baseFont
					}
				}

				LineGraph {
					id: netGraph
					anchors.top: downCol.bottom
					anchors.topMargin: Kirigami.Units.smallSpacing
					anchors.left: ifaceName.left
					anchors.right: parent.right
					anchors.rightMargin: Kirigami.Units.gridUnit * 0.5
					anchors.bottom: parent.bottom
					series: [
						{ color: card.downColor, fill: false, values: [] },
						{ color: card.upColor, fill: false, values: [] }
					]
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
