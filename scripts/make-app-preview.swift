// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Turns a Simulator screen recording into an App Store app preview: scaled to the accepted size,
// at most 30 fps, H.264, trimmed to a window, with the silent stereo AAC track Apple requires.
// No third-party tools.
//
//   swift scripts/make-app-preview.swift <in.mov> <out.mov> <width> <height> <start-end,start-end,…>
//   (seconds; the segments are joined in order with straight cuts)

import AVFoundation

let a = CommandLine.arguments
guard a.count == 6, let w = Double(a[3]), let h = Double(a[4]) else {
    print("usage: make-app-preview.swift in.mov out.mov width height start-end,start-end,…"); exit(1)
}
let segments: [CMTimeRange] = a[5].split(separator: ",").map { part in
    let p = part.split(separator: "-").compactMap { Double($0) }
    return CMTimeRange(start: CMTime(seconds: p[0], preferredTimescale: 600), end: CMTime(seconds: p[1], preferredTimescale: 600))
}
let length = segments.reduce(0) { $0 + $1.duration.seconds }
guard (15...30).contains(length) else { print("length \(length) s: Apple wants 15 to 30 s"); exit(1) }
let input = URL(fileURLWithPath: a[1]), output = URL(fileURLWithPath: a[2])
try? FileManager.default.removeItem(at: output)

let source = AVURLAsset(url: input)
let sourceTrack = try await source.loadTracks(withMediaType: .video)[0]
let natural = try await sourceTrack.load(.naturalSize)
let range = CMTimeRange(start: .zero, duration: CMTime(seconds: length, preferredTimescale: 600))

let comp = AVMutableComposition()
let video = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)!
var at = CMTime.zero
for seg in segments {
    try video.insertTimeRange(seg, of: sourceTrack, at: at)
    at = at + seg.duration
}

// A silent stereo track for the whole length: Apple requires an audio track.
let silenceURL = FileManager.default.temporaryDirectory.appendingPathComponent("silence-\(UUID().uuidString).caf")
let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
do {
    let file = try AVAudioFile(forWriting: silenceURL, settings: format.settings)
    let frames = AVAudioFrameCount(48_000 * (length + 1))
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
    buffer.frameLength = frames
    try file.write(from: buffer)
}
let silence = AVURLAsset(url: silenceURL)
let audio = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
try audio.insertTimeRange(CMTimeRange(start: .zero, duration: range.duration), of: try await silence.loadTracks(withMediaType: .audio)[0], at: .zero)

let videoComp = AVMutableVideoComposition()
videoComp.renderSize = CGSize(width: w, height: h)
videoComp.frameDuration = CMTime(value: 1, timescale: 30)
let instruction = AVMutableVideoCompositionInstruction()
instruction.timeRange = CMTimeRange(start: .zero, duration: range.duration)
let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: video)
let scale = max(w / natural.width, h / natural.height)
let dx = (w - natural.width * scale) / 2, dy = (h - natural.height * scale) / 2
layer.setTransform(CGAffineTransform(scaleX: scale, y: scale).concatenating(CGAffineTransform(translationX: dx, y: dy)), at: .zero)
instruction.layerInstructions = [layer]
videoComp.instructions = [instruction]

let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality)!
export.videoComposition = videoComp
export.audioMix = nil
try await export.export(to: output, as: .mov)
print("wrote \(output.path)")
