import XCTest
@testable import DeskHUDCore

final class HUDModelDecodingTests: XCTestCase {
    func testDecodesMinimalTwoSlotHUDDocument() throws {
        let json = #"""
        {
          "version": 1,
          "slots": [
            { "id": "leftDock", "anchor": "dock.left", "rotation": { "enabled": false, "intervalSeconds": 45 }, "items": [] },
            { "id": "rightDock", "anchor": "dock.right", "rotation": { "enabled": false, "intervalSeconds": 45 }, "items": [] }
          ]
        }
        """#.data(using: .utf8)!

        let document = try JSONDecoder().decode(HUDDocument.self, from: json)

        XCTAssertEqual(document.version, 1)
        XCTAssertEqual(document.slots.map(\.id), ["leftDock", "rightDock"])
        XCTAssertEqual(document.slots.map(\.anchor), [.dockLeft, .dockRight])
    }

    func testDecodesLowEffectConfig() throws {
        let json = #"""
        {
          "version": 1,
          "effectProfile": "low",
          "fullscreenMode": "overlay",
          "displays": "all",
          "backgroundStyle": "glass",
          "calendarEvents": false,
          "watchDirectory": null,
          "debugLogging": false,
          "window": {
            "width": 320,
            "height": 118,
            "margin": 18,
            "cornerRadius": 14,
            "opacity": 0.84,
            "maxLines": 4,
            "contentDensity": "comfortable",
            "scrollIntervalSeconds": 4,
            "durationSeconds": null
          }
        }
        """#.data(using: .utf8)!

        let config = try JSONDecoder().decode(HUDConfig.self, from: json)

        XCTAssertEqual(config.effectProfile, .low)
        XCTAssertEqual(config.fullscreenMode, .overlay)
        XCTAssertEqual(config.window.width, 320)
    }

    func testLoaderReportsInvalidJSONWithoutThrowing() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        try Data("{".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let result = HUDFileLoader().loadHUD(from: url)

        if case .failure(.decodeFailed) = result {
            return
        }
        XCTFail("Expected decodeFailed, got \(result)")
    }
}
