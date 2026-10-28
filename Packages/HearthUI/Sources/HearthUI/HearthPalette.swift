import SwiftUI

public enum HearthPalette {
    public static let ink = Color(red: 38 / 255, green: 43 / 255, blue: 68 / 255)
    public static let amber = Color(red: 253 / 255, green: 190 / 255, blue: 83 / 255)
    public static let grass = Color(red: 132 / 255, green: 198 / 255, blue: 105 / 255)
    public static let parchment = Color(red: 244 / 255, green: 234 / 255, blue: 214 / 255)
}

public struct TitleLabel: View {
    public init() {}

    public var body: some View {
        Text("Hearthdelve")
            .foregroundStyle(HearthPalette.amber)
    }
}
