import XCTest
@testable import Sysprite

final class MonitorTests: XCTestCase {

    func testCPUMonitorEmitsValueInRange() {
        let mon = CPUMonitor()
        let exp = expectation(description: "cpu")
        var received: Double?
        mon.onUpdate = { pct in
            if received == nil { received = pct; exp.fulfill() }
        }
        mon.start(interval: 0.2)
        wait(for: [exp], timeout: 5.0)
        mon.stop()
        XCTAssertNotNil(received)
        XCTAssertGreaterThanOrEqual(received!, 0)
        XCTAssertLessThanOrEqual(received!, 100)
    }

    func testMemoryMonitorEmitsSample() {
        let mon = MemoryMonitor()
        let exp = expectation(description: "mem")
        var received: MemorySample?
        mon.onUpdate = { s in
            if received == nil { received = s; exp.fulfill() }
        }
        mon.start(interval: 0.5)
        wait(for: [exp], timeout: 5.0)
        mon.stop()
        XCTAssertNotNil(received)
        XCTAssertGreaterThan(received!.totalBytes, 0)
        XCTAssertGreaterThan(received!.percent, 0)
        XCTAssertLessThanOrEqual(received!.percent, 100)
    }

    func testDiskMonitorEmitsCachedSampleQuickly() {
        let mon = DiskMonitor()
        let exp = expectation(description: "disk")
        var received: DiskSample?
        mon.onUpdate = { s in
            if received == nil { received = s; exp.fulfill() }
        }
        mon.start(tickInterval: 0.3)
        wait(for: [exp], timeout: 5.0)
        mon.stop()
        XCTAssertNotNil(received)
        XCTAssertGreaterThan(received!.totalBytes, 0)
    }

    func testNetworkMonitorEmitsAfterBaseline() {
        let mon = NetworkMonitor()
        let exp = expectation(description: "net")
        var samples = 0
        mon.onUpdate = { _ in
            samples += 1
            if samples == 1 { exp.fulfill() }
        }
        mon.start(interval: 0.5)
        wait(for: [exp], timeout: 5.0)
        mon.stop()
        XCTAssertGreaterThanOrEqual(samples, 1)
    }

    func testSettingsRoundTrip() {
        let s = Settings.shared
        let old = s.themeID
        s.themeID = "rabbit"
        XCTAssertEqual(s.themeID, "rabbit")
        s.themeID = old
    }

    func testSnapshotPersistJSONHasExpectedKeys() throws {
        let snap = Snapshot.shared
        snap.cpu = 42; snap.memory = 55; snap.pressure = 60
        snap.persist()
        let data = try Data(contentsOf: Snapshot.fileURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json?["cpu"])
        XCTAssertNotNil(json?["memory"])
        XCTAssertNotNil(json?["pressure"])
        XCTAssertNotNil(json?["timestamp"])
    }
}
