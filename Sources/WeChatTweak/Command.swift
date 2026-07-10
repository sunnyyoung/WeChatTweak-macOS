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

    static let defaultBinary = "Contents/MacOS/WeChat"

    /// Patches every target into its own binary (default `Contents/MacOS/WeChat`;
    /// WeChat 4.x targets `Contents/Resources/wechat.dylib`). Returns the unique
    /// bundle-relative paths that were touched, so `resign` can sign them first.
    @discardableResult
    static func patch(app: URL, config: Config) throws -> [String] {
        var patched: [String] = []
        for target in config.targets {
            let relative = target.binary ?? Command.defaultBinary
            print("------ Target: \(target.identifier) (\(relative)) ------")
            try Patcher.patch(binary: app.appendingPathComponent(relative), entries: target.entries)
            if !patched.contains(relative) {
                patched.append(relative)
            }
        }
        return patched
    }

    static func resign(app: URL, patchedBinaries: [String] = []) async throws {
        // Sign each patched nested binary first, so a modified dylib already carries
        // a valid ad-hoc signature before the app-level --deep re-sign wraps it.
        // Otherwise the running app can hit `Code Signature Invalid` on the patched page.
        for relative in patchedBinaries where relative != Command.defaultBinary {
            let path = app.appendingPathComponent(relative).path
            try await Command.execute(command: "codesign --force --sign - \(path)")
        }
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
