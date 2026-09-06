import QtQuick 2.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja Disk IO: título y una columna por disco con posición determinista
// (x = ancho * indice), separador vertical entre columnas y contenido anclado.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: Qt.rgba(15 / 255, 17 / 255, 21 / 255, 0.72)
	border.color: Qt.rgba(1, 1, 1, 0.08)
	border.width: 1

	readonly property color readColor: "#3fb9ff"
	readonly property color writeColor: "#ffb02e"
	readonly property int cellCount: monitorRoot ? Math.max(1, monitorRoot.disks.count) : 1
	readonly property int baseFont: Math.round(Kirigami.Units.gridUnit * 0.65)

	PlasmaComponents3.Label {
		id: title
		anchors.top: parent.top
		anchors.topMargin: Kirigami.Units.gridUnit * 0.4
		anchors.horizontalCenter: parent.horizontalCenter
		text: i18n("Disk IO")
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
			model: card.monitorRoot ? card.monitorRoot.disks : []

			Item {
				id: cell
				required property int index
				required property string name
				required property string diskModel
				required property real temp
				required property real read
				required property real write

				x: parent.width * cell.index / card.cellCount
				width: parent.width / card.cellCount
				height: parent.height

				// Separación vertical por disco (salvo el primero)
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
					id: diskName
					anchors.top: parent.top
					anchors.left: parent.left
					anchors.leftMargin: cell.index > 0 ? Kirigami.Units.largeSpacing : 0
					text: cell.name
					color: "#ffffff"
					font.bold: true
					font.pixelSize: card.baseFont
				}

				// Temperatura del disco en rojo, a la derecha (solo con sensor)
				PlasmaComponents3.Label {
					id: diskTemp
					visible: cell.temp > 0
					anchors.top: parent.top
					anchors.right: parent.right
					anchors.rightMargin: Kirigami.Units.gridUnit * 0.5
					text: cell.temp > 0 ? Math.round(cell.temp) + " °C" : ""
					color: "#ff5555"
					font.bold: true
					font.pixelSize: card.baseFont
				}

				PlasmaComponents3.Label {
					anchors.top: parent.top
					anchors.left: diskName.right
					anchors.leftMargin: Kirigami.Units.smallSpacing
					anchors.right: diskTemp.visible ? diskTemp.left : parent.right
					anchors.rightMargin: Kirigami.Units.smallSpacing
					elide: Text.ElideMiddle
					text: cell.diskModel
					color: "#ffffff"
					opacity: 0.45
					font.pixelSize: card.baseFont
				}

				Row {
					id: rwRow
					anchors.top: diskName.bottom
					anchors.topMargin: Kirigami.Units.smallSpacing
					anchors.left: diskName.left
					spacing: Kirigami.Units.smallSpacing

					PlasmaComponents3.Label {
						text: i18n("Read")
						color: "#ffffff"
						opacity: 0.55
						font.pixelSize: card.baseFont
					}
					PlasmaComponents3.Label {
						text: card.monitorRoot ? card.monitorRoot.fmtBytes(cell.read) + "/s" : ""
						color: card.readColor
						font.bold: true
						font.pixelSize: card.baseFont
					}
				}

				Row {
					anchors.top: diskName.bottom
					anchors.topMargin: Kirigami.Units.smallSpacing
					anchors.right: parent.right
					anchors.rightMargin: Kirigami.Units.gridUnit * 0.5
					spacing: Kirigami.Units.smallSpacing

					PlasmaComponents3.Label {
						text: i18n("Write")
						color: "#ffffff"
						opacity: 0.55
						font.pixelSize: card.baseFont
					}
					PlasmaComponents3.Label {
						text: card.monitorRoot ? card.monitorRoot.fmtBytes(cell.write) + "/s" : ""
						color: card.writeColor
						font.bold: true
						font.pixelSize: card.baseFont
					}
				}

				LineGraph {
					id: ioGraph
					anchors.top: rwRow.bottom
					anchors.topMargin: Kirigami.Units.smallSpacing
					anchors.left: diskName.left
					anchors.right: parent.right
					anchors.rightMargin: Kirigami.Units.gridUnit * 0.5
					anchors.bottom: parent.bottom
					series: [
						{ color: card.readColor, fill: false, values: [] },
						{ color: card.writeColor, fill: false, values: [] }
					]
				}

				onReadChanged: ioGraph.push(0, read)
				onWriteChanged: ioGraph.push(1, write)
				Component.onCompleted: {
					ioGraph.push(0, 0)
					ioGraph.push(1, 0)
				}
			}
		}

		PlasmaComponents3.Label {
			visible: !card.monitorRoot || card.monitorRoot.disks.count === 0
			anchors.centerIn: parent
			text: i18n("Sin discos")
			color: "#ffffff"
			opacity: 0.5
		}
	}
}
