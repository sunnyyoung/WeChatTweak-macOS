import Foundation
import MachO

private func u32(_ value: UInt32) -> Data {
    var value = value.littleEndian
    return Data(bytes: &value, count: 4)
}

private func u64(_ value: UInt64) -> Data {
    var value = value.littleEndian
    return Data(bytes: &value, count: 8)
}

private func fixture(trailingMalformedCommand: Bool = false) -> Data {
    var data = Data()
    data.append(u32(MH_MAGIC_64))
    data.append(u32(UInt32(CPU_TYPE_ARM64)))
    data.append(u32(0))
    data.append(u32(2))
    data.append(u32(trailingMalformedCommand ? 2 : 1))
    data.append(u32(trailingMalformedCommand ? 80 : 72))
    data.append(u32(0))
    data.append(u32(0))

    data.append(u32(UInt32(LC_SEGMENT_64)))
    data.append(u32(72))
    var name = Data("__TEXT".utf8)
    name.append(Data(repeating: 0, count: 16 - name.count))
    data.append(name)
    data.append(u64(0x1000))
    data.append(u64(0x100))
    data.append(u64(0x100))
    data.append(u64(0x100))
    data.append(u32(7))
    data.append(u32(5))
    data.append(u32(0))
    data.append(u32(0))
    if trailingMalformedCommand {
        data.append(u32(0))
        data.append(u32(0))
    }

    data.append(Data(repeating: 0, count: 0x100 - data.count))
    data.append(Data(repeating: 0, count: 0x100))
    data.replaceSubrange(0x100..<0x104, with: Data([0x11, 0x11, 0x11, 0x11]))
    data.replaceSubrange(0x104..<0x108, with: Data([0x22, 0x22, 0x22, 0x22]))
    return data
}

private func config(_ entries: String, version: String = "test") throws -> Config {
    let json = """
    {"version":"\(version)","targets":[{"identifier":"test","entries":[\(entries)]}]}
    """
    return try JSONDecoder().decode(Config.self, from: Data(json.utf8))
}

private enum TestError: Swift.Error {
    case failed(String)
}

private func expectFailure(_ message: String, _ body: () throws -> Void) throws {
    do {
        try body()
        throw TestError.failed("expected failure: \(message)")
    } catch let error as TestError {
        throw error
    } catch {}
}

@main
struct Main {
    static func main() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let binary = root.appendingPathComponent("fixture")

        let first = "{\"arch\":\"arm64\",\"addr\":\"1000\",\"expected\":\"11111111\",\"asm\":\"AAAAAAAA\"}"
        let secondBad = "{\"arch\":\"arm64\",\"addr\":\"1004\",\"expected\":\"DEADBEEF\",\"asm\":\"BBBBBBBB\"}"
        try fixture().write(to: binary)
        try expectFailure("later expected mismatch") {
            try Patcher.patch(binary: binary, config: try config("\(first),\(secondBad)"))
        }
        let unchanged = try Data(contentsOf: binary)
        guard unchanged[0x100..<0x108] == Data([0x11, 0x11, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22]),
              !FileManager.default.fileExists(atPath: binary.path + ".test.bak") else {
            throw TestError.failed("validation failure changed file or created backup")
        }

        let second = "{\"arch\":\"arm64\",\"addr\":\"1004\",\"expected\":\"22222222\",\"asm\":\"BBBBBBBB\"}"
        let valid = try config("\(first),\(second)")
        try Patcher.patch(binary: binary, config: valid)
        try Patcher.patch(binary: binary, config: valid)
        let patched = try Data(contentsOf: binary)
        let backup = try Data(contentsOf: URL(fileURLWithPath: binary.path + ".test.bak"))
        guard patched[0x100..<0x108] == Data([0xAA, 0xAA, 0xAA, 0xAA, 0xBB, 0xBB, 0xBB, 0xBB]),
              backup[0x100..<0x108] == Data([0x11, 0x11, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22]) else {
            throw TestError.failed("write, idempotence, or backup failed")
        }

        for (label, entries) in [
            ("boundary", "{\"arch\":\"arm64\",\"addr\":\"10FE\",\"asm\":\"AAAAAAAA\"}"),
            ("empty", "{\"arch\":\"arm64\",\"addr\":\"1000\",\"asm\":\"\"}"),
            ("overlap", "\(first),{\"arch\":\"arm64\",\"addr\":\"1002\",\"asm\":\"BBBBBBBB\"}")
        ] {
            try fixture().write(to: binary)
            try? FileManager.default.removeItem(atPath: binary.path + ".test.bak")
            try expectFailure(label) { try Patcher.patch(binary: binary, config: try config(entries)) }
            guard try Data(contentsOf: binary) == fixture() else {
                throw TestError.failed("\(label) changed file")
            }
        }

        try fixture(trailingMalformedCommand: true).write(to: binary)
        try expectFailure("malformed trailing command") {
            try Patcher.patch(binary: binary, config: try config(first))
        }
        guard try Data(contentsOf: binary) == fixture(trailingMalformedCommand: true) else {
            throw TestError.failed("malformed command changed file")
        }

        print("patcher safety tests passed")
    }
}
