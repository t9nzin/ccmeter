import AppKit

enum MenuBarIcon {
    private static let iconSize: CGFloat = 18

    // Claude logo bezier path, parsed once from SVG data
    private static let basePath: NSBezierPath = parseSVGPath(claudeLogoSVG, flipY: 146)

    /// Generates an 18x18 template image of the Claude logo with circular progress fill.
    static func generateIcon(percentage: Double) -> NSImage {
        let size = NSSize(width: iconSize, height: iconSize)
        let image = NSImage(size: size, flipped: false) { rect in
            drawIcon(in: rect, percentage: percentage)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func drawIcon(in rect: NSRect, percentage: Double) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let path = scaledPath(fitting: rect)

        // Always show outline
        NSColor.black.setStroke()
        path.lineWidth = 0.4
        path.stroke()

        // Circular fill sweeping clockwise from 12 o'clock
        let pct = min(max(percentage, 0), 100)
        if pct > 0 {
            drawFill(center: center, path: path, percentage: pct)
        }
    }

    private static func drawFill(center: CGPoint, path: NSBezierPath, percentage: Double) {
        let angle = CGFloat(percentage / 100.0) * 360.0

        let sector = NSBezierPath()
        sector.move(to: center)
        sector.appendArc(
            withCenter: center,
            radius: iconSize,
            startAngle: 90,
            endAngle: 90 - angle,
            clockwise: true
        )
        sector.close()

        NSGraphicsContext.saveGraphicsState()
        sector.addClip()
        NSColor.black.setFill()
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func scaledPath(fitting rect: NSRect) -> NSBezierPath {
        guard let path = basePath.copy() as? NSBezierPath else { return NSBezierPath() }
        let b = path.bounds
        guard b.width > 0, b.height > 0 else { return path }

        let padding: CGFloat = 1.0
        let available = min(rect.width, rect.height) - padding * 2
        let scale = available / max(b.width, b.height)

        // Move origin to (0,0), scale, then center in rect
        var t1 = AffineTransform.identity
        t1.translate(x: -b.origin.x, y: -b.origin.y)
        path.transform(using: t1)

        var t2 = AffineTransform.identity
        t2.scale(scale)
        path.transform(using: t2)

        let sb = path.bounds
        var t3 = AffineTransform.identity
        t3.translate(x: rect.midX - sb.midX, y: rect.midY - sb.midY)
        path.transform(using: t3)

        return path
    }

    // MARK: - SVG Path Parser (handles M, C, z)

    private static func parseSVGPath(_ d: String, flipY: CGFloat) -> NSBezierPath {
        let tokens = tokenize(d)
        let path = NSBezierPath()
        let fy = Double(flipY)
        var i = 0

        while i < tokens.count {
            switch tokens[i] {
            case "M":
                guard i + 2 < tokens.count,
                      let x = Double(tokens[i + 1]),
                      let y = Double(tokens[i + 2]) else { i += 1; continue }
                path.move(to: CGPoint(x: x, y: fy - y))
                i += 3
            case "C":
                i += 1
                while i + 5 < tokens.count,
                      let x1 = Double(tokens[i]),
                      let y1 = Double(tokens[i + 1]),
                      let x2 = Double(tokens[i + 2]),
                      let y2 = Double(tokens[i + 3]),
                      let x3 = Double(tokens[i + 4]),
                      let y3 = Double(tokens[i + 5]) {
                    path.curve(
                        to: CGPoint(x: x3, y: fy - y3),
                        controlPoint1: CGPoint(x: x1, y: fy - y1),
                        controlPoint2: CGPoint(x: x2, y: fy - y2)
                    )
                    i += 6
                }
            case "z", "Z":
                path.close()
                i += 1
            default:
                i += 1
            }
        }
        return path
    }

    private static func tokenize(_ d: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        for char in d {
            if char.isLetter {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(char))
            } else if char == "," || char.isWhitespace {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    // MARK: - Claude logo SVG path data (viewBox 0 0 112 146)

    // swiftlint:disable line_length
    private static let claudeLogoSVG = """
    M41.330677,71.670403 \
    C37.316444,64.391510 33.255619,57.137665 29.320202,49.816410 \
    C28.315273,47.946892 26.779953,45.671227 27.142502,43.925747 \
    C27.641455,41.523537 29.226847,38.507542 31.233973,37.468838 \
    C33.788277,36.146961 36.571964,37.495571 38.040890,40.698483 \
    C43.023483,51.562782 48.180954,62.346882 53.871086,74.435143 \
    C54.671093,66.679871 55.327499,60.216331 56.008636,53.755394 \
    C56.357529,50.445965 56.191311,46.932060 57.321854,43.908382 \
    C58.066273,41.917423 60.707672,40.635738 62.499634,39.036453 \
    C63.515083,41.219700 65.598640,43.530701 65.355507,45.563412 \
    C64.448784,53.144154 62.774170,60.632767 61.401951,68.158546 \
    C61.257030,68.953362 61.206116,69.765312 61.889927,71.076241 \
    C64.095871,68.350235 66.256889,65.586319 68.518105,62.906960 \
    C72.060371,58.709660 75.643967,54.546413 79.261803,50.414055 \
    C81.334724,48.046326 83.979233,46.814262 86.678734,48.970268 \
    C89.500778,51.224159 89.937233,54.470211 87.860275,57.473743 \
    C84.927246,61.715256 81.613602,65.691383 78.568237,69.858124 \
    C76.331673,72.918243 74.264488,76.102142 71.209251,80.563416 \
    C79.424767,79.065529 86.144142,77.832428 92.867401,76.620857 \
    C94.338768,76.355713 95.963829,75.685707 97.267715,76.064362 \
    C98.930428,76.547218 100.338715,77.906212 101.856659,78.887543 \
    C100.631462,80.242149 99.625595,82.416595 98.144035,82.812958 \
    C90.759575,84.788528 83.247086,86.283585 75.786781,87.979126 \
    C74.050789,88.373672 72.342636,88.890724 70.718025,90.113632 \
    C77.994331,90.441513 85.273216,90.723297 92.545113,91.129951 \
    C94.343803,91.230537 96.541290,91.198174 97.804047,92.186729 \
    C99.546600,93.550903 100.576103,95.825890 101.911026,97.710747 \
    C99.599167,98.617012 97.115021,100.580109 95.006912,100.236450 \
    C87.965027,99.088531 81.061592,97.098328 74.095261,95.473038 \
    C72.895271,95.193062 71.647171,95.119301 69.899864,95.843491 \
    C75.712112,101.224037 81.644287,106.483444 87.269585,112.052811 \
    C89.161079,113.925507 92.929733,115.100296 91.325775,119.118698 \
    C88.820671,118.091164 86.043106,117.457832 83.867271,115.953918 \
    C79.356918,112.836403 75.166252,109.256371 70.844147,105.866516 \
    C70.490181,106.203247 70.136223,106.539978 69.782257,106.876717 \
    C71.388870,109.024437 73.027008,111.149513 74.591721,113.327339 \
    C75.757210,114.949547 76.873695,116.611343 77.930153,118.306519 \
    C79.710533,121.163322 82.025597,124.767372 78.736794,127.196793 \
    C74.848747,130.068878 72.987907,125.814667 71.190247,123.159531 \
    C67.003052,116.975060 62.938068,110.707848 57.986504,103.205956 \
    C57.251480,109.931915 56.630356,115.507195 56.037220,121.085457 \
    C55.702911,124.229546 55.272289,127.372879 55.146645,130.526978 \
    C55.025997,133.555618 53.374676,135.999954 50.766499,135.101242 \
    C49.036106,134.505005 47.275997,131.061386 47.308853,128.919678 \
    C47.368935,125.003731 48.806194,121.119316 49.561527,117.201012 \
    C50.500507,112.330009 51.330406,107.437988 51.201042,102.007843 \
    C50.108704,103.322014 48.988178,104.613899 47.928799,105.954117 \
    C42.769264,112.481483 37.755241,119.131691 32.366978,125.463791 \
    C31.302752,126.714447 28.820475,126.758415 26.992161,127.358871 \
    C27.197107,125.455063 26.742111,123.073624 27.716791,121.726913 \
    C33.045525,114.364197 38.725456,107.255653 43.733334,99.277260 \
    C42.966244,99.510933 42.097778,99.586426 41.447865,100.002945 \
    C35.425213,103.862724 29.458557,107.809982 23.429279,111.659225 \
    C22.182774,112.455025 20.748468,113.442360 19.392603,113.454781 \
    C17.798925,113.469360 16.196402,112.517227 14.597714,111.984337 \
    C15.174429,110.416862 15.284965,108.179985 16.408426,107.397591 \
    C21.317257,103.978981 26.491709,100.935326 31.625914,97.849007 \
    C35.140759,95.736130 38.748135,93.777184 42.314144,91.749428 \
    C42.221992,91.301666 42.129841,90.853912 42.037689,90.406151 \
    C40.351753,90.275833 38.667961,90.093765 36.979523,90.023880 \
    C28.160887,89.658875 19.340834,89.328163 10.521995,88.967880 \
    C9.527703,88.927254 8.246878,89.128517 7.607266,88.601112 \
    C6.313939,87.534660 5.369678,86.044884 4.281472,84.729668 \
    C5.668284,84.121056 7.081342,82.936073 8.437627,82.997841 \
    C16.915970,83.383926 25.381952,84.043831 33.851322,84.623375 \
    C36.591690,84.810898 39.329937,85.029442 42.439323,84.218407 \
    C37.536198,80.913025 32.618805,77.628555 27.734177,74.296059 \
    C23.331802,71.292572 18.900845,68.324272 14.607024,65.170883 \
    C12.006742,63.261230 10.392917,60.526718 12.405514,57.495216 \
    C14.778397,53.921040 17.825125,55.227955 20.600771,57.309048 \
    C27.128340,62.203224 33.639969,67.118660 40.609325,72.322861 \
    C41.326500,72.567238 41.592400,72.514244 41.858295,72.461250 \
    C41.682423,72.197632 41.506550,71.934021 41.330677,71.670403 \
    z
    """
    // swiftlint:enable line_length
}
