import Foundation
import XCTest

/// Runs the real binary in separate processes, so Swift's per-process hash seeding would show up as a mismatch.
final class ReplayTests: XCTestCase {
    func testTwoProcessesAgreeAndReplayMatches() throws {
        let content = repoRoot().appendingPathComponent("Content").path
        let recording = FileManager.default.temporaryDirectory.appendingPathComponent("hd-replay-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: recording) }
        let args = ["room", "--seed", "7", "--ticks", "1200", "--taps", "40:flask,41:ward,300:potion,600:flask", "--content", content]

        let first = try launch(args + ["--record", recording.path])
        let second = try launch(args)
        XCTAssertEqual(first.status, 0)
        XCTAssertEqual(hashLine(first.output), hashLine(second.output))
        XCTAssertNotNil(hashLine(first.output))

        let replay = try launch(["replay", "--recording", recording.path, "--content", content])
        XCTAssertEqual(replay.status, 0, replay.output)
        XCTAssertTrue(replay.output.contains("\nmatch"))

        var tampered = try JSONSerialization.jsonObject(with: Data(contentsOf: recording)) as! [String: Any]
        tampered["endHash"] = 1
        try JSONSerialization.data(withJSONObject: tampered).write(to: recording)
        let mismatch = try launch(["replay", "--recording", recording.path, "--content", content])
        XCTAssertEqual(mismatch.status, 2)
    }

    func testValidateAndSmokePass() throws {
        let content = repoRoot().appendingPathComponent("Content").path
        let validate = try launch(["validate", "--content", content])
        XCTAssertEqual(validate.status, 0, validate.output)
        let smoke = try launch(["smoke", "--content", content, "--ticks", "600"])
        XCTAssertEqual(smoke.status, 0, smoke.output)
    }

    private func hashLine(_ output: String) -> String? {
        output.split(separator: "\n").first { $0.hasPrefix("hash ") }.map(String.init)
    }

    private func launch(_ args: [String]) throws -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = productsDirectory().appendingPathComponent("HearthSimCLI")
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }

    private func productsDirectory() -> URL {
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        return Bundle.main.bundleURL
    }

    private func repoRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.path != "/" {
            if FileManager.default.fileExists(atPath: url.appendingPathComponent("Content/tuning.json").path) { return url }
            url.deleteLastPathComponent()
        }
        return url
    }
}
