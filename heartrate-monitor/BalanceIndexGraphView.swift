//
//  BalanceIndexGraphView.swift
//  heartrate-monitor
//
//  Created by Kosuke Miyoshi on 2016/01/30.
//  Copyright © 2016年 narrative nigths. All rights reserved.
//

import Foundation
import AppKit

class BalanceIndexGraphView: NSView {
	var logSpectrumData: LogSpectrumData!

	func setLogSpectrumData(logSpectrumData: LogSpectrumData) {
		self.logSpectrumData = logSpectrumData
		needsDisplay = true
	}

	private func drawHorizontalGridValue(value: Double, x: Double, y: Double) {
		let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		style.alignment = NSTextAlignment.center
        let attr: [NSAttributedStringKey : Any] = [
            .paragraphStyle : style,
        ]
		let str = NSString(string: String(format: "%.1f", value))
        str.draw(in: CGRect(x:x - 20.0, y:y - 20, width:40.0, height:40.0), withAttributes: attr)
	}

	private func drawHorizontalString(str: String, x: Double, y: Double) {
		let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		style.alignment = NSTextAlignment.center
        let attr: [NSAttributedStringKey : Any] = [
            .paragraphStyle : style,
        ]
        str.draw(in: CGRect(x:x - 50.0, y:y - 20, width: 100.0, height:40.0), withAttributes: attr)
	}

	private func drawVerticalGridValue(value: Double, x: Double, y: Double) {
		var str: NSString! = nil
		if value >= 1000.0 {
			str = NSString(string: String(format: "%.0fK", value / 1000.0))
		} else if value >= 1.0 {
			str = NSString(string: String(format: "%.0f", value))
		} else {
			let logValue = round(log10(value))
			str = NSString(string: String(format: "1E%d", Int(logValue)))
		}

		drawVerticalString(str: String(str), x: x, y: y)
	}

	private func drawVerticalString(str: String, x: Double, y: Double) {
		let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
		style.alignment = NSTextAlignment.right
        let attr: [NSAttributedStringKey : Any] = [
            .paragraphStyle : style,
        ]
        str.draw(in: CGRect( x: x - 100.0, y:y - 8, width: 100.0, height: 16.0), withAttributes: attr)
	}

	private func getGridUnit(maxValue: Double) -> Double {
		let d = maxValue / 10.0

		var base10 = 1.0
		var base = base10

		while true {
			if base10 >= d {
				base = base10
				break
			}
			let base25 = base10 * 2.5
			if base25 >= d {
				base = base25
				break
			}

			let base50 = base10 * 5.0
			if base50 >= d {
				base = base50
				break
			}
			base10 *= 10.0
		}
		return base
	}

    private func drawLineWithStartX(startX: Double, startY: Double, endX: Double, endY: Double, lineWidth:CGFloat=0.2) {
		let path: NSBezierPath = NSBezierPath()
		path.lineWidth = lineWidth
		path.move(to: NSPoint(x: startX, y: startY))
		path.line(to: NSPoint(x: endX, y: endY))
		path.stroke()
	}

	private func drawGrid() {
		let pointCount = logSpectrumData.pointCount

		let minPsd = logSpectrumData.minLogPsd
		let maxPsd = logSpectrumData.maxLogPsd
		let minFreq = logSpectrumData.minLogFreq
		let maxFreq = logSpectrumData.maxLogFreq

		let marginX = 60.0
		let marginY = 40.0

		let width = Double(frame.width) - 2.0 * marginX
		let height = Double(frame.height) - 2.0 * marginY

		let scaleX = width / (maxFreq - minFreq)
		let scaleY = height / (maxPsd - minPsd)

		let axisColor = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
		let gridColor = NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)

		// Grid X axis
		let minX = floor(minFreq)
		let maxX = ceil(maxFreq)

		// Axis X Line
		axisColor.set()
		drawLineWithStartX(startX: marginX, startY: marginY, endX: marginX, endY: marginY + height)

		// each X grid
		gridColor.set()
       
        var x = minX
        while x <= maxX + 0.0001 {
			if x >= minFreq && x < maxFreq {
				// vertical line
				let px: Double = (x - minFreq) * scaleX + marginX
				drawLineWithStartX(startX: px, startY: marginY, endX: px, endY: marginY + height)
				drawHorizontalGridValue(value: pow(10.0, x), x: px, y: 10.0)
			}
            
            x += 1.0
		}

		// Grid X Label
		drawHorizontalString(str: "Frequency (Hz)", x: marginX + width * 0.5, y: -5.0)

		// Grid Y axis
		let minY = floor(minPsd)
		let maxY = ceil(maxPsd)

		// Axis Y Line
		axisColor.set()
		drawLineWithStartX(startX: marginX, startY: marginY, endX: marginX + width, endY: marginY)

		// each Y grid
		gridColor.set()

        var y = minY
        while y <= maxY {
			if y >= minPsd && y <= maxPsd {
				// horizontal line
				let py: Double = (y - minPsd) * scaleY + marginY
				drawLineWithStartX(startX: marginX, startY: py, endX: marginX + width, endY: py)
				drawVerticalGridValue(value: pow(10.0, y), x: 50, y: py)
			}
            y += 1.0
		}

		// Y Label
		drawVerticalString(str: "PSD", x: 25, y: marginY + height * 0.5)

		// Spectrum Graph line
		let lineColor = NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
		lineColor.set()

		var px = (logSpectrumData.points[0].logFrequency - minFreq) * scaleX + marginX
		var py = (logSpectrumData.points[0].logPsd - minPsd) * scaleY + marginY

		let path: NSBezierPath = NSBezierPath()
		path.lineWidth = 0.3
		path.move(to: NSPoint(x: px, y: py))

		for i in 1 ..< pointCount {
			px = (logSpectrumData.points[i].logFrequency - minFreq) * scaleX + marginX
			py = (logSpectrumData.points[i].logPsd - minPsd) * scaleY + marginY
			path.line(to: NSPoint(x: px, y: py))
			path.stroke()
		}

		// Slope
		let (a, b) = logSpectrumData.calcSlope()

		let x0 = minFreq
		let y0 = minFreq * a + b

		let x1 = maxFreq
		let y1 = maxFreq * a + b

		let px0: Double = (x0 - minFreq) * scaleX + marginX
		let py0: Double = (y0 - minPsd) * scaleY + marginY
		let px1: Double = (x1 - minFreq) * scaleX + marginX
		let py1: Double = (y1 - minPsd) * scaleY + marginY

		let slopeColor = NSColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
		slopeColor.set()
		drawLineWithStartX(startX: px0, startY: py0, endX: px1, endY: py1, lineWidth: 0.4)
	}

	override func draw(_ rect: CGRect) {
		super.draw(rect)

		if logSpectrumData == nil {
			return
		}

		drawGrid()
	}
}
