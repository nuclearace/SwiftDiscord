// The MIT License (MIT)
// Copyright (c) 2021 fwcd

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.

public struct DiscordSticker: Identifiable, Codable {
    public enum CodingKeys: String, CodingKey {
        case id
        case packId = "pack_id"
        case name
        case description
        case tags
        case asset
        case previewAsset = "preview_asset"
        case formatType = "format_type"
    }

    /// ID of the sticker
    public let id: Snowflake
    /// ID of the sticker pack
    public let packId: Snowflake
    /// Name of the sticker
    public let name: String
    /// Description of the sticker
    public let description: String
    /// List of tags for the sticker
    public let tags: [String]
    /// Sticker asset hash
    public let asset: String?
    /// Sticker preview asset hash
    public let previewAsset: String?
    /// Type of sticker format
    public let formatType: DiscordStickerFormatType?
}

public struct DiscordStickerFormatType: RawRepresentable, Codable {
    public var rawValue: Int

    public static let png = DiscordStickerFormatType(rawValue: 1)
    public static let apng = DiscordStickerFormatType(rawValue: 2)
    public static let lottie = DiscordStickerFormatType(rawValue: 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
