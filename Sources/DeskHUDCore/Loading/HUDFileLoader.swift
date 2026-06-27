import Foundation

public enum HUDFileLoaderError: Error, CustomStringConvertible, Equatable, Sendable {
    case fileNotFound(String)
    case readFailed(String)
    case decodeFailed(String)

    public var description: String {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .readFailed(let message):
            return "Read failed: \(message)"
        case .decodeFailed(let message):
            return "Decode failed: \(message)"
        }
    }
}

public struct HUDFileLoader: Sendable {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func loadConfig(from url: URL) -> Result<HUDConfig, HUDFileLoaderError> {
        decode(HUDConfig.self, from: url)
    }

    public func loadHUD(from url: URL) -> Result<HUDDocument, HUDFileLoaderError> {
        decode(HUDDocument.self, from: url)
    }

    public func decode<T: Decodable>(_ type: T.Type, from url: URL) -> Result<T, HUDFileLoaderError> {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return .failure(.fileNotFound(url.path))
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return .failure(.readFailed(error.localizedDescription))
        }

        do {
            return .success(try decoder.decode(T.self, from: data))
        } catch {
            return .failure(.decodeFailed(error.localizedDescription))
        }
    }
}
