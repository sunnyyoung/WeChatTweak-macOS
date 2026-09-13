//
//  Patcher.swift
//  WeChatTweak
//
//  Created by Sunny Young on 2025/12/4.
//

import Darwin
import MachO
import Foundation

struct Patcher {
    enum Error: Swift.Error {
        case invalidFile
        case not64BitMachO(magic: UInt32)
        case vaNotFound(arch: String, va: UInt64)
        case emptyPatch(arch: String, va: UInt64)
        case unexpectedBytes(arch: String, va: UInt64)
        case overlappingPatches
        case noArchMatched
    }

    private struct Slice {
        let cpu: UInt32
        let offset: UInt64
        let size: UInt64
    }

    private struct PatchPlan {
        let archName: String
        let targetVA: UInt64
        let fileOffset: UInt64
        let patch: Data
        let original: Data

        var isAlreadyPatched: Bool { original == patch }
    }

    static func patch(binary: URL, config: Config) throws {
        guard FileManager.default.fileExists(atPath: binary.path) else {
            throw Error.invalidFile
        }

        let entries = config.targets.flatMap { $0.entries }
        guard !entries.isEmpty else { throw Error.noArchMatched }
        for entry in entries {
            guard !entry.asm.isEmpty else {
                throw Error.emptyPatch(arch: entry.arch.rawValue, va: entry.addr)
            }
            if let expected = entry.expected, expected.count != entry.asm.count {
                throw Error.unexpectedBytes(arch: entry.arch.rawValue, va: entry.addr)
            }
        }

        let fh = try FileHandle(forUpdating: binary)
        defer { try? fh.close() }

        guard flock(fh.fileDescriptor, LOCK_EX) == 0 else { throw Error.invalidFile }
        defer { flock(fh.fileDescriptor, LOCK_UN) }

        let fileSize = try fh.seekToEnd()
        let slices = try parseSlices(file: fh, fileSize: fileSize)
        var plans: [PatchPlan] = []

        for slice in slices {
            let matching = entries.filter { $0.arch.cpu == slice.cpu }
            for target in matching {
                plans.append(try makePlan(file: fh,
                                          fileSize: fileSize,
                                          slice: slice,
                                          target: target))
            }
        }

        guard !plans.isEmpty else { throw Error.noArchMatched }
        try validateNoOverlaps(plans)

        // Nothing is written until every target and its expected original bytes pass validation.
        try backup(binary: binary, version: config.version)
        try ensureUnchanged(plans, file: fh, fileSize: fileSize)

        do {
            for plan in plans where !plan.isAlreadyPatched {
                try fh.seek(toOffset: plan.fileOffset)
                try fh.write(contentsOf: plan.patch)
                print("[\(plan.archName)] patch VA=\(String(format: "0x%llx", plan.targetVA)), fileoff=\(String(format: "0x%llx", plan.fileOffset))")
            }
            try fh.synchronize()
            for plan in plans {
                let written = try readExactly(file: fh,
                                              offset: plan.fileOffset,
                                              count: plan.patch.count,
                                              fileSize: fileSize)
                guard written == plan.patch else { throw Error.invalidFile }
            }
        } catch {
            // Restore ranges already attempted so a write failure does not leave a mixed patch set.
            for plan in plans where !plan.isAlreadyPatched {
                try? fh.seek(toOffset: plan.fileOffset)
                try? fh.write(contentsOf: plan.original)
            }
            try? fh.synchronize()
            throw error
        }

        for plan in plans where plan.isAlreadyPatched {
            print("[\(plan.archName)] VA=\(String(format: "0x%llx", plan.targetVA)) already patched, skipped")
        }
    }

    private static func parseSlices(file fh: FileHandle, fileSize: UInt64) throws -> [Slice] {
        let magicData = try readExactly(file: fh, offset: 0, count: 4, fileSize: fileSize)
        let magicBE = readUInt32BE(magicData, at: 0)

        if magicBE == FAT_MAGIC || magicBE == FAT_CIGAM {
            let header = try readExactly(file: fh, offset: 0, count: 8, fileSize: fileSize)
            let swapped = magicBE == FAT_CIGAM
            let nfat = swapped ? readUInt32LE(header, at: 4) : readUInt32BE(header, at: 4)
            let (tableSize, tableOverflow) = UInt64(nfat).multipliedReportingOverflow(by: 20)
            let (tableEnd, endOverflow) = UInt64(8).addingReportingOverflow(tableSize)
            guard !tableOverflow, !endOverflow, tableEnd <= fileSize else { throw Error.invalidFile }

            var slices: [Slice] = []
            slices.reserveCapacity(Int(nfat))
            for index in 0..<UInt64(nfat) {
                let entryOffset = 8 + index * 20
                let data = try readExactly(file: fh, offset: entryOffset, count: 20, fileSize: fileSize)
                let cpu = swapped ? readUInt32LE(data, at: 0) : readUInt32BE(data, at: 0)
                let offset = UInt64(swapped ? readUInt32LE(data, at: 8) : readUInt32BE(data, at: 8))
                let size = UInt64(swapped ? readUInt32LE(data, at: 12) : readUInt32BE(data, at: 12))
                guard offset >= tableEnd,
                      size >= 32,
                      let sliceEnd = adding(offset, size),
                      sliceEnd <= fileSize else {
                    throw Error.invalidFile
                }
                slices.append(Slice(cpu: cpu, offset: offset, size: size))
            }
            let sortedSlices = slices.sorted { $0.offset < $1.offset }
            for (previous, current) in zip(sortedSlices, sortedSlices.dropFirst()) {
                guard let previousEnd = adding(previous.offset, previous.size),
                      previousEnd <= current.offset else {
                    throw Error.invalidFile
                }
            }
            return slices
        }

        let header = try readExactly(file: fh, offset: 0, count: 32, fileSize: fileSize)
        let magic = readUInt32LE(header, at: 0)
        guard magic == MH_MAGIC_64 else { throw Error.not64BitMachO(magic: magic) }
        return [Slice(cpu: readUInt32LE(header, at: 4), offset: 0, size: fileSize)]
    }

    private static func makePlan(file fh: FileHandle,
                                 fileSize: UInt64,
                                 slice: Slice,
                                 target: Config.Entry) throws -> PatchPlan {
        let header = try readExactly(file: fh, offset: slice.offset, count: 32, fileSize: fileSize)
        let magic = readUInt32LE(header, at: 0)
        guard magic == MH_MAGIC_64 else { throw Error.not64BitMachO(magic: magic) }
        guard readUInt32LE(header, at: 4) == slice.cpu else { throw Error.invalidFile }

        let ncmds = readUInt32LE(header, at: 16)
        let sizeofcmds = UInt64(readUInt32LE(header, at: 20))
        guard let sliceEnd = adding(slice.offset, slice.size),
              let commandsStart = adding(slice.offset, 32),
              let commandsEnd = adding(commandsStart, sizeofcmds),
              commandsEnd <= sliceEnd,
              commandsEnd <= fileSize else {
            throw Error.invalidFile
        }

        var commandOffset = commandsStart
        var plan: PatchPlan?
        for _ in 0..<ncmds {
            guard let commandHeaderEnd = adding(commandOffset, 8), commandHeaderEnd <= commandsEnd else {
                throw Error.invalidFile
            }
            let commandHeader = try readExactly(file: fh, offset: commandOffset, count: 8, fileSize: fileSize)
            let command = readUInt32LE(commandHeader, at: 0)
            let commandSize = UInt64(readUInt32LE(commandHeader, at: 4))
            guard commandSize >= 8,
                  let nextCommand = adding(commandOffset, commandSize),
                  nextCommand <= commandsEnd else {
                throw Error.invalidFile
            }

            if command == LC_SEGMENT_64 {
                guard commandSize >= 72 else { throw Error.invalidFile }
                let segment = try readExactly(file: fh, offset: commandOffset + 8, count: 64, fileSize: fileSize)
                let name = String(bytes: segment.prefix { $0 != 0 }, encoding: .utf8) ?? ""
                let vmaddr = readUInt64LE(segment, at: 16)
                let vmsize = readUInt64LE(segment, at: 24)
                let fileoff = readUInt64LE(segment, at: 32)
                let filesize = readUInt64LE(segment, at: 40)

                guard let segmentFileEnd = adding(fileoff, filesize), segmentFileEnd <= slice.size else {
                    throw Error.invalidFile
                }

                if target.addr >= vmaddr {
                    let offsetInSegment = target.addr - vmaddr
                    if offsetInSegment < vmsize {
                        guard plan == nil else { throw Error.invalidFile }
                        guard name == "__TEXT",
                              let patchLength = UInt64(exactly: target.asm.count),
                              let patchEndInSegment = adding(offsetInSegment, patchLength),
                              patchEndInSegment <= vmsize,
                              patchEndInSegment <= filesize,
                              let relativeFileOffset = adding(fileoff, offsetInSegment),
                              let absoluteFileOffset = adding(slice.offset, relativeFileOffset),
                              let absoluteEnd = adding(absoluteFileOffset, patchLength),
                              absoluteEnd <= sliceEnd,
                              absoluteEnd <= fileSize else {
                            throw Error.vaNotFound(arch: target.arch.rawValue, va: target.addr)
                        }

                        let current = try readExactly(file: fh,
                                                      offset: absoluteFileOffset,
                                                      count: target.asm.count,
                                                      fileSize: fileSize)
                        if current != target.asm, let expected = target.expected, current != expected {
                            throw Error.unexpectedBytes(arch: target.arch.rawValue, va: target.addr)
                        }
                        plan = PatchPlan(archName: target.arch.rawValue,
                                         targetVA: target.addr,
                                         fileOffset: absoluteFileOffset,
                                         patch: target.asm,
                                         original: current)
                    }
                }
            }

            commandOffset = nextCommand
        }

        guard commandOffset == commandsEnd else { throw Error.invalidFile }
        if let plan { return plan }
        throw Error.vaNotFound(arch: target.arch.rawValue, va: target.addr)
    }

    private static func validateNoOverlaps(_ plans: [PatchPlan]) throws {
        let sorted = plans.sorted { $0.fileOffset < $1.fileOffset }
        for (previous, current) in zip(sorted, sorted.dropFirst()) {
            guard let previousEnd = adding(previous.fileOffset, UInt64(previous.patch.count)),
                  previousEnd <= current.fileOffset else {
                throw Error.overlappingPatches
            }
        }
    }

    private static func ensureUnchanged(_ plans: [PatchPlan], file fh: FileHandle, fileSize: UInt64) throws {
        for plan in plans {
            let current = try readExactly(file: fh,
                                          offset: plan.fileOffset,
                                          count: plan.original.count,
                                          fileSize: fileSize)
            guard current == plan.original else {
                throw Error.unexpectedBytes(arch: plan.archName, va: plan.targetVA)
            }
        }
    }

    /// Keep the first same-version copy so it remains a recovery point for the original binary.
    private static func backup(binary: URL, version: String) throws {
        guard !version.isEmpty, !version.contains("/"), !version.utf8.contains(0) else {
            throw Error.invalidFile
        }
        let backupURL = URL(fileURLWithPath: binary.path + "." + version + ".bak")
        guard !FileManager.default.fileExists(atPath: backupURL.path) else { return }
        try FileManager.default.copyItem(at: binary, to: backupURL)
        print("Backup created: \(backupURL.path)")
    }

    private static func readExactly(file fh: FileHandle,
                                    offset: UInt64,
                                    count: Int,
                                    fileSize: UInt64) throws -> Data {
        guard count >= 0,
              let length = UInt64(exactly: count),
              let end = adding(offset, length),
              end <= fileSize else {
            throw Error.invalidFile
        }
        try fh.seek(toOffset: offset)
        guard let data = try fh.read(upToCount: count), data.count == count else {
            throw Error.invalidFile
        }
        return data
    }

    private static func adding(_ lhs: UInt64, _ rhs: UInt64) -> UInt64? {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? nil : result
    }

    private static func readUInt32LE(_ data: Data, at offset: Int) -> UInt32 {
        data[offset..<(offset + 4)].enumerated().reduce(0) { result, item in
            result | (UInt32(item.element) << UInt32(item.offset * 8))
        }
    }

    private static func readUInt32BE(_ data: Data, at offset: Int) -> UInt32 {
        data[offset..<(offset + 4)].reduce(0) { ($0 << 8) | UInt32($1) }
    }

    private static func readUInt64LE(_ data: Data, at offset: Int) -> UInt64 {
        data[offset..<(offset + 8)].enumerated().reduce(0) { result, item in
            result | (UInt64(item.element) << UInt64(item.offset * 8))
        }
    }
}
