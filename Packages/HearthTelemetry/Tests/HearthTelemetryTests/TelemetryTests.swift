import XCTest
@testable import HearthTelemetry

final class TelemetryTests: XCTestCase {
    func testEveryFixtureStaysInsideFirebaseLimits() throws {
        let router = TelemetryRouter(sessionID: "session", sinks: [])
        XCTAssertEqual(GameEvent.fixtures.count, 31)
        var names = Set<String>()
        for event in GameEvent.fixtures {
            let name = event.mapped.name
            XCTAssertTrue(names.insert(name).inserted, name)
            XCTAssertLessThanOrEqual(name.count, 40)
            XCTAssertFalse(name.hasPrefix("firebase_"))
            XCTAssertFalse(name.hasPrefix("google_"))
            XCTAssertFalse(name.hasPrefix("ga_"))
            XCTAssertNil(event.mapped.parameters["session_id"])
            let payload = router.payload(for: event)
            XCTAssertLessThanOrEqual(payload.count, 15)
            XCTAssertEqual(payload["session_id"], "session")
            try router.emit(event)
        }
        let riftEnd = try XCTUnwrap(GameEvent.fixtures.first { $0.mapped.name == "rift_end" })
        XCTAssertEqual(router.payload(for: riftEnd).count, 15)
    }
}
