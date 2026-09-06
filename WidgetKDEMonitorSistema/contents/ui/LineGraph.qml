import QtQuick 2.15
import org.kde.kirigami as Kirigami

// Gráfica de líneas al estilo de kde-glassy-system-monitor (MIT, Muddyblack):
// líneas suavizadas con beziers, glow de trazo ancho a baja alfa, relleno con
// degradado fijo de arriba (0.35) a la base (0) y escala Y continua sin
// redondear a "números bonitos" — el redondeo hacía saltar la línea entera.
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

	// "#rrggbb" -> {r,g,b} para degradados y alfas
	function hexRgb(hex) {
		var h = String(hex).replace("#", "")
		if (h.length === 8) h = h.substr(2)
		return {
			r: parseInt(h.substr(0, 2), 16),
			g: parseInt(h.substr(2, 2), 16),
			b: parseInt(h.substr(4, 2), 16)
		}
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

		// Márgenes verticales como Glassy: 6% arriba y abajo, 88% útil
		var tPad = h * 0.06, uH = h * 0.88
		var top = tPad, bottom = h - tPad

		var yMax = 100
		if (!percent) {
			var m = 0
			for (var s = 0; s < series.length; s++) {
				var vals = series[s].values
				for (var i = 0; i < vals.length; i++) {
					if (vals[i] > m) m = vals[i]
				}
			}
			yMax = Math.max(1024, m * 1.2)
		}

		var axisW = Math.min(w * 0.28, Math.round(Kirigami.Units.gridUnit * 2.2))
		var gx = axisW, gw = w - axisW

		// Rejilla discontinua + etiquetas: número en negrita y unidad más
		// pequeña debajo, alineadas a la derecha (3 marcas: max, medio y 0)
		ctx.setLineDash([3, 5])
		ctx.lineWidth = 0.5
		ctx.strokeStyle = "rgba(255,255,255,0.12)"
		var numFont = Math.round(Kirigami.Units.gridUnit * 0.5)
		var unitFont = Math.round(Kirigami.Units.gridUnit * 0.38)
		ctx.textAlign = "right"
		ctx.textBaseline = "middle"
		for (var g = 0; g < 3; g++) {
			var frac = g / 2
			var y = bottom - frac * uH
			ctx.beginPath()
			ctx.moveTo(gx, y)
			ctx.lineTo(w, y)
			ctx.stroke()
			var txt = fmtAxis(yMax * frac)
			var sp = txt.lastIndexOf(" ")
			if (sp > 0) {
				ctx.font = "bold " + numFont + "px sans-serif"
				ctx.fillStyle = "rgba(255,255,255,0.65)"
				ctx.fillText(txt.slice(0, sp), gx - 4, y - unitFont * 0.6)
				ctx.font = unitFont + "px sans-serif"
				ctx.fillStyle = "rgba(255,255,255,0.38)"
				ctx.fillText(txt.slice(sp + 1), gx - 4, y + unitFont * 0.8)
			} else {
				ctx.font = "bold " + numFont + "px sans-serif"
				ctx.fillStyle = "rgba(255,255,255,0.65)"
				ctx.fillText(txt, gx - 4, y)
			}
		}
		ctx.setLineDash([])

		var dx = maxPoints > 1 ? gw / (maxPoints - 1) : 0

		// Sin datos: línea discontinua en el medio, como el estado idle de Glassy
		var any = false
		for (var c = 0; c < series.length && !any; c++) any = series[c].values.length > 0
		if (!any) {
			ctx.lineWidth = 1
			ctx.strokeStyle = "rgba(255,255,255,0.18)"
			ctx.setLineDash([4, 6])
			ctx.beginPath()
			ctx.moveTo(gx, h / 2)
			ctx.lineTo(w, h / 2)
			ctx.stroke()
			ctx.setLineDash([])
			return
		}

		function yv(val) {
			return bottom - Math.min(1, Math.max(0, val / yMax)) * uH
		}

		// Se dibujan en orden inverso: la primera serie queda ENCIMA
		// (download sobre upload, como Glassy)
		for (var k = series.length - 1; k >= 0; k--) {
			var ser = series[k]
			var v = ser.values
			if (v.length < 2) continue
			var n = v.length
			var rgb = hexRgb(ser.color)

			ctx.save()
			ctx.beginPath()
			ctx.rect(gx, 0, gw, h)
			ctx.clip()
			ctx.lineCap = "round"
			ctx.lineJoin = "round"

			// Trazo suavizado: bezier con puntos de control en el punto medio x.
			// Se construye aparte el path para poder reutilizarlo en el relleno
			function tracePath() {
				ctx.beginPath()
				ctx.moveTo(w - (n - 1) * dx, yv(v[0]))
				for (var j = 1; j < n; j++) {
					var x = w - (n - 1 - j) * dx
					var px = w - (n - j) * dx
					var cx = (px + x) / 2
					ctx.bezierCurveTo(cx, yv(v[j - 1]), cx, yv(v[j]), x, yv(v[j]))
				}
			}

			// Relleno: de 0 a la línea en TODO el histórico. Se recorta al polígono
			// bajo la curva y se pinta en columnas finas con gradiente anclado a la y
			// INTERPOLADA de la curva en esa columna: anclar al extremo del segmento
			// deja escalones (tinte fuerte junto al pico, casi nada en la vaguada)
			// que a simple vista se leen como cuñas o una X
			if (ser.fill) {
				ctx.save()
				tracePath()
				ctx.lineTo(w, bottom)
				ctx.lineTo(w - (n - 1) * dx, bottom)
				ctx.closePath()
				ctx.clip()
				var xFirst = w - (n - 1) * dx
				var step = 3
				for (var fx = xFirst; fx < w; fx += step) {
					var fi = (fx - xFirst) / dx
					var i0 = Math.max(0, Math.min(n - 1, Math.floor(fi)))
					var i1 = Math.min(n - 1, i0 + 1)
					var ty = yv(v[i0]) + (yv(v[i1]) - yv(v[i0])) * (fi - i0)
					var gr = ctx.createLinearGradient(0, ty, 0, bottom)
					gr.addColorStop(0, "rgba(" + rgb.r + "," + rgb.g + "," + rgb.b + ",0.35)")
					gr.addColorStop(1, "rgba(" + rgb.r + "," + rgb.g + "," + rgb.b + ",0)")
					ctx.fillStyle = gr
					ctx.fillRect(fx, 0, step + 0.75, h)
				}
				ctx.restore()
			}

			tracePath()

			// Glow: mismo path trazado con ancho grande y alfa baja (sin shadowBlur)
			ctx.strokeStyle = "rgba(" + rgb.r + "," + rgb.g + "," + rgb.b + ",0.22)"
			ctx.lineWidth = 7
			ctx.stroke()

			ctx.strokeStyle = String(ser.color)
			ctx.lineWidth = 2
			ctx.stroke()
			ctx.restore()
		}
	}
}
