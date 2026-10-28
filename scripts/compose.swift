// Puts two captures side by side, with a label above each.
//   swift scripts/compose.swift image <left.png> <right.png> <out.png> <left label> <right label>
//   swift scripts/compose.swift video <left.mp4> <right.mp4> <out.mp4> <left label> <right label>
//   swift scripts/compose.swift gif   <left.mp4> <right.mp4> <out.gif> <left label> <right label> [fps] [scale]
//   swift scripts/compose.swift frames <video.mp4> <out dir> <fps> [scale]      one PNG per frame, named by ms
import AVFoundation
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let gap: CGFloat = 24
let labelHeight: CGFloat = 110

func loadImage(_ path: String) -> CGImage {
  guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
    fatalError("cannot read \(path)")
  }
  return image
}

func drawLabel(_ text: String, in rect: CGRect, context: CGContext) {
  let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 64, nil)
  let attributes = [
    kCTFontAttributeName: font,
    kCTForegroundColorAttributeName: CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
  ] as CFDictionary
  let line = CTLineCreateWithAttributedString(CFAttributedStringCreate(nil, text as CFString, attributes))
  let bounds = CTLineGetBoundsWithOptions(line, [])
  context.textPosition = CGPoint(x: rect.midX - bounds.width / 2, y: rect.midY - bounds.height / 2 + 8)
  CTLineDraw(line, context)
}

func compose(_ left: CGImage, _ right: CGImage, labels: (String, String), scale: CGFloat = 1) -> CGImage {
  let width = CGFloat(left.width + right.width) + gap
  let height = CGFloat(max(left.height, right.height)) + labelHeight
  let outWidth = Int(width * scale), outHeight = Int(height * scale)
  let space = CGColorSpace(name: CGColorSpace.sRGB)!
  let context = CGContext(data: nil, width: outWidth, height: outHeight, bitsPerComponent: 8, bytesPerRow: 0,
                          space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.scaleBy(x: scale, y: scale)
  context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  let leftWidth = CGFloat(left.width)
  context.draw(left, in: CGRect(x: 0, y: 0, width: leftWidth, height: CGFloat(left.height)))
  context.draw(right, in: CGRect(x: leftWidth + gap, y: 0, width: CGFloat(right.width), height: CGFloat(right.height)))
  drawLabel(labels.0, in: CGRect(x: 0, y: height - labelHeight, width: leftWidth, height: labelHeight), context: context)
  drawLabel(labels.1, in: CGRect(x: leftWidth + gap, y: height - labelHeight, width: CGFloat(right.width), height: labelHeight), context: context)
  return context.makeImage()!
}

/// A copy of the image at the given scale.
func scaled(_ image: CGImage, by scale: CGFloat) -> CGImage {
  if scale == 1 { return image }
  let width = Int(CGFloat(image.width) * scale), height = Int(CGFloat(image.height) * scale)
  let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.interpolationQuality = .high
  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  return context.makeImage()!
}

func writeImage(_ image: CGImage, to path: String) {
  let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(destination, image, nil)
  CGImageDestinationFinalize(destination)
}

/// Frames of a video at a fixed rate.
func frames(of path: String, fps: Double, duration: Double) -> [CGImage] {
  let asset = AVURLAsset(url: URL(fileURLWithPath: path))
  let generator = AVAssetImageGenerator(asset: asset)
  generator.appliesPreferredTrackTransform = true
  generator.requestedTimeToleranceBefore = .zero
  generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5 / fps, preferredTimescale: 600)
  var result: [CGImage] = []
  var t = 0.0
  while t < duration {
    let time = CMTime(seconds: t, preferredTimescale: 600)
    if let image = try? generator.copyCGImage(at: time, actualTime: nil) {
      result.append(image)
    } else if let last = result.last {
      result.append(last)
    }
    t += 1 / fps
  }
  return result
}

func seconds(of path: String) -> Double {
  CMTimeGetSeconds(AVURLAsset(url: URL(fileURLWithPath: path)).duration)
}

func writeGif(_ images: [CGImage], fps: Double, to path: String) {
  let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.gif.identifier as CFString, images.count, nil)!
  CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
  for image in images {
    let props = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps]] as CFDictionary
    CGImageDestinationAddImage(destination, image, props)
  }
  CGImageDestinationFinalize(destination)
}

func writeVideo(_ images: [CGImage], fps: Double, to path: String) throws {
  try? FileManager.default.removeItem(atPath: path)
  let writer = try AVAssetWriter(outputURL: URL(fileURLWithPath: path), fileType: .mp4)
  let width = images[0].width, height = images[0].height
  let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height
  ])
  let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height
  ])
  writer.add(input)
  writer.startWriting()
  writer.startSession(atSourceTime: .zero)
  for (index, image) in images.enumerated() {
    while !input.isReadyForMoreMediaData { usleep(5000) }
    var buffer: CVPixelBuffer?
    CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32ARGB, nil, &buffer)
    guard let buffer else { fatalError("no pixel buffer") }
    CVPixelBufferLockBaseAddress(buffer, [])
    let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    CVPixelBufferUnlockBaseAddress(buffer, [])
    adaptor.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(fps)))
  }
  input.markAsFinished()
  let done = DispatchSemaphore(value: 0)
  writer.finishWriting { done.signal() }
  done.wait()
  if let error = writer.error { throw error }
}

let args = CommandLine.arguments
if args.count >= 5, args[1] == "frames" {
  let fps = Double(args[4]) ?? 10
  let scale = args.count > 5 ? Double(args[5]) ?? 1 : 1
  try? FileManager.default.createDirectory(atPath: args[3], withIntermediateDirectories: true)
  for (index, frame) in frames(of: args[2], fps: fps, duration: seconds(of: args[2])).enumerated() {
    let ms = Int(Double(index) * 1000 / fps)
    writeImage(scaled(frame, by: CGFloat(scale)), to: String(format: "%@/f_%05d.png", args[3], ms))
  }
  print("wrote frames to \(args[3])"); exit(0)
}
guard args.count >= 7 else {
  print("usage: see header comment"); exit(2)
}
let mode = args[1], left = args[2], right = args[3], out = args[4]
let labels = (args[5], args[6])
switch mode {
case "image":
  writeImage(compose(loadImage(left), loadImage(right), labels: labels), to: out)
case "video", "gif":
  let fps = args.count > 7 ? Double(args[7]) ?? 10 : (mode == "gif" ? 8 : 20)
  let scale = args.count > 8 ? Double(args[8]) ?? 1 : (mode == "gif" ? 0.3 : 0.5)
  let duration = min(seconds(of: left), seconds(of: right))
  let pairs = zip(frames(of: left, fps: fps, duration: duration), frames(of: right, fps: fps, duration: duration))
  let composed = pairs.map { compose($0, $1, labels: labels, scale: CGFloat(scale)) }
  if mode == "gif" { writeGif(composed, fps: fps, to: out) } else { try writeVideo(composed, fps: fps, to: out) }
default:
  print("unknown mode \(mode)"); exit(2)
}
print("wrote \(out)")
