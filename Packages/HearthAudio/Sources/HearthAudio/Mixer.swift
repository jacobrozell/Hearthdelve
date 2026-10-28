import AVFoundation

public enum AudioBus: String, Sendable, CaseIterable {
    case music
    case ambience
    case sfx
    case ui
}

public struct AudioLevels: Sendable, Equatable {
    public var music: Float
    public var ambience: Float
    public var sfx: Float
    public var ui: Float

    public static let specDefaults = AudioLevels(music: 0.7, ambience: 0.7, sfx: 0.8, ui: 1)
}

@MainActor
public final class HearthMixer {
    public let engine = AVAudioEngine()

    public init() {}
}
