import QtQuick 2.15
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Layout del boceto: fila [GPU|temp][CPU|temp] con las parejas pegadas,
// Disk IO y Network a ancho completo repartiéndose en columnas por unidad.
ColumnLayout {
	id: full

	property var monitorRoot

	Layout.minimumWidth: Kirigami.Units.gridUnit * 46
	Layout.minimumHeight: Kirigami.Units.gridUnit * 34

	spacing: Kirigami.Units.gridUnit * 0.7

	RowLayout {
		Layout.fillWidth: true
		Layout.fillHeight: true
		spacing: Kirigami.Units.gridUnit

		// GPU + barra de temperatura pegadas
		RowLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: Kirigami.Units.smallSpacing * 0.5

			SectionGpu {
				monitorRoot: full.monitorRoot
				Layout.fillWidth: true
				Layout.fillHeight: true
			}

			TempStrip {
				title: i18n("Temp")
				temp: full.monitorRoot ? full.monitorRoot.gpuTemp : 0
				Layout.preferredWidth: Kirigami.Units.gridUnit * 1.3
				Layout.fillHeight: true
			}
		}

		// CPU + barra de temperatura pegadas
		RowLayout {
			Layout.fillWidth: true
			Layout.fillHeight: true
			spacing: Kirigami.Units.smallSpacing * 0.5

			SectionCpu {
				monitorRoot: full.monitorRoot
				Layout.fillWidth: true
				Layout.fillHeight: true
			}

			TempStrip {
				title: i18n("Temp")
				temp: full.monitorRoot ? full.monitorRoot.cpuTemp : 0
				Layout.preferredWidth: Kirigami.Units.gridUnit * 1.3
				Layout.fillHeight: true
			}
		}
	}

	SectionDisks {
		monitorRoot: full.monitorRoot
		Layout.fillWidth: true
		Layout.fillHeight: true
	}

	SectionNetwork {
		monitorRoot: full.monitorRoot
		Layout.fillWidth: true
		Layout.fillHeight: true
	}
}
