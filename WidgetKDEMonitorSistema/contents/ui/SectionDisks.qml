import QtQuick 2.15
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami as Kirigami

// Caja Disk IO: una columna por disco fijo encontrado, separadas por una línea
// vertical. La temperatura (NVMe) va en rojo junto al nombre; los HDD sin
// sensor simplemente no la muestran.
Rectangle {
	id: card

	property var monitorRoot: null

	radius: Kirigami.Units.largeSpacing
	color: Qt.rgba(15/255, 17/255, 21/255, 0.72)
	border.color: Qt.rgba(1, 1, 1, 0.08)
	border.width: 1

	readonly property color readColor: "#3fb9ff"
	readonly property color writeColor: "#ffb02e"

	ColumnLayout {
		anchors.fill: parent
		anchors.margins: Kirigami.Units.gridUnit * 0.6
		spacing: Kirigami.Units.smallSpacing

		PlasmaComponents3.Label {
			Layout.alignment: Qt.AlignHCenter
			text: i18n("Disk IO")
			font.bold: true
			font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.9)
			color: "#ffffff"
		}

		RowLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: 0

			Repeater {
				model: monitorRoot ? monitorRoot.disks : []

				// Cada disco: separador (menos el primero) + celda a partes iguales
				RowLayout {
					id: diskPair
					required property int index
					required property string name
					required property string diskModel
					required property real temp
					required property real read
					required property real write
					Layout.fillWidth: true
					Layout.fillHeight: true
					spacing: 0

					Rectangle {
						visible: index > 0
						Layout.fillHeight: true
						Layout.preferredWidth: 1
						Layout.topMargin: Kirigami.Units.smallSpacing
						Layout.bottomMargin: Kirigami.Units.smallSpacing
						color: Qt.rgba(1, 1, 1, 0.15)
					}

					ColumnLayout {
						Layout.fillWidth: true
						Layout.fillHeight: true
						Layout.leftMargin: index > 0 ? Kirigami.Units.largeSpacing : 0
						Layout.rightMargin: Kirigami.Units.largeSpacing
						spacing: 0

						RowLayout {
							Layout.fillWidth: true

							PlasmaComponents3.Label {
								text: diskPair.name
								font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
								font.bold: true
								color: "#ffffff"
							}

							PlasmaComponents3.Label {
								Layout.fillWidth: true
								elide: Text.ElideMiddle
								text: diskPair.diskModel
								font: Kirigami.Theme.smallFont
								opacity: 0.45
								color: "#ffffff"
							}

							// Temperatura del disco en rojo (solo si hay sensor)
							PlasmaComponents3.Label {
								visible: diskPair.temp > 0
								text: diskPair.temp > 0 ? Math.round(diskPair.temp) + " °C" : ""
								font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
								font.bold: true
								color: "#ff5555"
							}
						}

						RowLayout {
							Layout.fillWidth: true

							PlasmaComponents3.Label {
								text: i18n("Read")
								font: Kirigami.Theme.smallFont
								opacity: 0.55
								color: "#ffffff"
							}
							PlasmaComponents3.Label {
								text: monitorRoot ? monitorRoot.fmtBytes(diskPair.read) + "/s" : ""
								font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
								font.bold: true
								color: card.readColor
							}
							Item { Layout.fillWidth: true }
							PlasmaComponents3.Label {
								text: i18n("Write")
								font: Kirigami.Theme.smallFont
								opacity: 0.55
								color: "#ffffff"
							}
							PlasmaComponents3.Label {
								text: monitorRoot ? monitorRoot.fmtBytes(diskPair.write) + "/s" : ""
								font.pixelSize: Math.round(Kirigami.Units.gridUnit * 0.75)
								font.bold: true
								color: card.writeColor
							}
						}

						LineGraph {
							id: ioGraph
							Layout.fillWidth: true
							Layout.fillHeight: true
							series: [
								{ color: card.readColor, fill: false, values: [] },
								{ color: card.writeColor, fill: false, values: [] }
							]
						}
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
				visible: !monitorRoot || monitorRoot.disks.count === 0
				Layout.fillWidth: true
				Layout.fillHeight: true
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				text: i18n("Sin discos")
				opacity: 0.5
				color: "#ffffff"
			}
		}
	}
}
