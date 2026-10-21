import Foundation
import SwiftData

/// A saved heart-sound recording. The app records and plays it back; it does not
/// analyze or classify it.
@Model
final class HeartSoundRecording {
    var timestamp: Date
    var fileURLString: String
    var notes: String

    /// Recordings are stored as a bare filename resolved against the permanent
    /// HeartSoundStore directory. Legacy absolute/file URLs are still tolerated.
    var fileURL: URL? {
        if fileURLString.hasPrefix("file:") {
            return URL(string: fileURLString)
        }
        if fileURLString.hasPrefix("/") {
            return URL(fileURLWithPath: fileURLString)
        }
        return HeartSoundStore.url(for: fileURLString)
    }

    init(timestamp: Date = .now, fileURLString: String, notes: String = "") {
        self.timestamp = timestamp
        self.fileURLString = fileURLString
        self.notes = notes
    }
}
