//
//  Command.swift
//  Created by Sunny Young.
//

import Foundation

struct Command {
    enum Error: LocalizedError {
        case executing(command: String, status: Int32, output: String)

        var errorDescription: String? {
            switch self {
            case let .executing(command, status, output):
                return "\(command) failed (\(status)): \(output)"
            }
        }
    }

    static func version(app: URL) async throws -> String? {
        let data = try Data(contentsOf: app.appendingPathComponent("Contents/Info.plist"))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return (plist as? [String: Any])?["CFBundleVersion"] as? String
    }

    static func patch(app: URL, config: Config) async throws {
        let binary = config.binary ?? .executable
        let url = app.appendingPathComponent("Contents").appendingPathComponent(binary.rawValue)
        print("Patch binary: \(url.path)")
        try Patcher.patch(binary: url, config: config)
    }

    static func resign(app: URL) async throws {
        // Resources dylibs are not guaranteed to be discovered as nested code by --deep.
        let library = app.appendingPathComponent("Contents/Resources/wechat.dylib")
        if FileManager.default.fileExists(atPath: library.path) {
            try execute("/usr/bin/codesign", ["--force", "--sign", "-", library.path])
        }
        try execute("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", app.path])
        try execute("/usr/bin/xattr", ["-cr", app.path])
        try execute("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
    }

    private static func execute(_ executable: String, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let output = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw Error.executing(command: executable, status: process.terminationStatus,
                output: String(decoding: output, as: UTF8.self))
        }
    }
}
