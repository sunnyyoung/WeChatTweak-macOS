//
//  Command.swift
//
//  Created by Sunny Young.
//

import Foundation
import ArgumentParser

struct Command {
    enum Error: @unchecked Sendable, LocalizedError {
        case executing(command: String, error: NSDictionary)

        var errorDescription: String? {
            switch self {
            case let .executing(command, error):
                return "executing: \(command) error: \(error)"
            }
        }
    }

    static func version(app: URL) async throws -> String? {
        try await Command.execute(command: "defaults read \(app.appendingPathComponent("Contents/Info.plist").path) CFBundleVersion")
    }

    static func patch(app: URL, config: Config) async throws {
        let dylibURL = app.appendingPathComponent("Contents/Frameworks/wechat.dylib")
        let mainURL = app.appendingPathComponent("Contents/MacOS/WeChat")

        // Check for the newer directory structure first: if wechat.dylib exists, patch it only.
        // Otherwise, fall back to the main WeChat binary.
        let targetURL = FileManager.default.fileExists(atPath: dylibURL.path) ? dylibURL : mainURL
        try Patcher.patch(binary: targetURL, config: config)
    }

    static func resign(app: URL) async throws {
        try await Command.execute(command: "codesign --remove-sign \(app.path)")
        try await Command.execute(command: "codesign --force --deep --sign - \(app.path)")
        try await Command.execute(command: "xattr -cr \(app.path)")
    }

    @discardableResult
    private static func execute(command: String) async throws -> String? {
        guard let script = NSAppleScript(source: "do shell script \"\(command)\"") else {
            throw Error.executing(
                command: command,
                error: ["error": "Create script failed."]
            )
        }

        var error: NSDictionary?
        let descriptor = script.executeAndReturnError(&error)

        if let error = error {
            throw Error.executing(
                command: command,
                error: error
            )
        } else {
            return descriptor.stringValue
        }
    }
}
