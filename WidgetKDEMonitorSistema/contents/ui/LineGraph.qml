import QtQuick 2.15
import org.kde.kirigami as Kirigami

// Gráfica de líneas estilo sensor nativo: rejilla horizontal, etiquetas Y a la
// izquierda y series con relleno en degradado opcional (GPU/CPU lo usan).
Canvas {
	id: canvas

	property var series: []          // [{color, fill, values:[]}]
	property bool percent: false     // true: eje Y fijo 0-100; false: escala automática
	property int maxPoints: 60

	antialiasing: true

	onSeriesChanged: requestPaint()
	onWidthChanged: requestPaint()
	onHeightChanged: requestPaint()

	function push(index, value) {
		if (!series || !series[index]) return
		var vals = series[index].values
		vals.push(Number(value) || 0)
		while (vals.length > maxPoints) vals.shift()
		requestPaint()
	}

	// Redondea el máximo de la escala a un número "bonito" para las etiquetas
	function niceMax(m) {
		if (m <= 0) return 1024
		var e = Math.pow(10, Math.floor(Math.log(m) / Math.LN10))
		var f = m / e
		var nf = f <= 1 ? 1 : f <= 2 ? 2 : f <= 5 ? 5 : 10
		return nf * e
	}

	// "#rrggbb" -> "rgba(r,g,b,a)" para los degradados (el color viaja como string)
	function hexRgba(hex, a) {
		var h = String(hex).replace("#", "")
		if (h.length === 8) h = h.substr(2)
		var r = parseInt(h.substr(0, 2), 16)
		var g = parseInt(h.substr(2, 2), 16)
		var b = parseInt(h.substr(4, 2), 16)
		return "rgba(" + r + "," + g + "," + b + "," + a + ")"
	}

	function fmtAxis(v) {
		if (percent) return Math.round(v) + "%"
		var u = ["B", "K", "M", "G"]
		var i = 0
		while (v >= 1024 && i < u.length - 1) { v /= 1024; i++ }
		return (v >= 100 ? v.toFixed(0) : v.toFixed(1)) + u[i]
	}

	onPaint: {
		var ctx = getContext("2d")
		var w = width, h = height
		ctx.clearRect(0, 0, w, h)
		if (!series || series.length === 0) return

		// Las etiquetas del eje Y se pisan con los bordes si van al ras:
		// se les reserva medio texto arriba y abajo y un margen a la izquierda
		var labelH = Math.round(Kirigami.Units.gridUnit * 0.55)
		var top = Math.ceil(labelH / 2) + 2
		var bottom = h - Math.ceil(labelH / 2) - 2

		var yMax = percent ? 100 : 1024
		if (!percent) {
			var m = 0
			for (var s = 0; s < series.length; s++) {
				var vals = series[s].values
				for (var i = 0; i < vals.length; i++) {
					if (vals[i] > m) m = vals[i]
				}
			}
			yMax = niceMax(m * 1.25)
		}

		var axisW = Math.min(w * 0.22, Kirigami.Units.gridUnit * 3)
		var gx = axisW, gw = w - axisW

		// Rejilla y etiquetas Y (3 marcas como los widgets nativos)
		ctx.strokeStyle = "rgba(255,255,255,0.10)"
		ctx.lineWidth = 1
		ctx.font = Math.round(Kirigami.Units.gridUnit * 0.55) + "px sans-serif"
		ctx.fillStyle = "rgba(255,255,255,0.45)"
		ctx.textAlign = "left"
		ctx.textBaseline = "middle"
		for (var g = 0; g < 3; g++) {
			var frac = g / 2
			var y = bottom - frac * (bottom - top)
			if (g > 0) {
				ctx.beginPath()
				ctx.moveTo(gx, y)
				ctx.lineTo(w, y)
				ctx.stroke()
			}
			ctx.fillText(fmtAxis(yMax * frac), 5, y)
		}

		var dx = maxPoints > 1 ? gw / (maxPoints - 1) : 0

		for (var k = 0; k < series.length; k++) {
			var ser = series[k]
			var v = ser.values
			if (v.length < 2) continue
			var n = v.length
			var yv = function(val) {
				return bottom - Math.min(1, Math.max(0, val / yMax)) * (bottom - top)
			}
			ctx.beginPath()
			for (var j = 0; j < n; j++) {
				var x = w - (n - 1 - j) * dx
				if (j === 0) ctx.moveTo(x, yv(v[j]))
				else ctx.lineTo(x, yv(v[j]))
			}
			if (ser.fill) {
				// Cerrar el polígono por abajo (último punto → base derecha → base izquierda)
				// y rellenar con degradado desde la línea actual hasta 0,
				// no desde el techo del gráfico: si no, con la línea baja el relleno
				// queda en la zona casi transparente del degradado
				ctx.save()
				ctx.lineTo(w, bottom)
				ctx.lineTo(w - (n - 1) * dx, bottom)
				ctx.closePath()
				var yNow = yv(v[n - 1])
				var grad = ctx.createLinearGradient(0, yNow, 0, bottom)
				grad.addColorStop(0, hexRgba(ser.color, 0.35))
				grad.addColorStop(1, hexRgba(ser.color, 0))
				ctx.fillStyle = grad
				ctx.fill()
				ctx.restore()
				// Redibujar el trazo porque el fill consume el path
				ctx.beginPath()
				for (var j2 = 0; j2 < n; j2++) {
					var x2 = w - (n - 1 - j2) * dx
					if (j2 === 0) ctx.moveTo(x2, yv(v[j2]))
					else ctx.lineTo(x2, yv(v[j2]))
				}
			}
			ctx.strokeStyle = ser.color
			ctx.lineWidth = 2
			ctx.lineJoin = "round"
			ctx.lineCap = "round"
			ctx.stroke()
		}
	}
}
