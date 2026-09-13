#!/usr/bin/env python3
"""Cross-version offset locator for maintaining config.json.

WeChat 4.x is Qt/C++ with almost no ObjC metadata, so function offsets cannot
be recovered from method names. This tool locates the stub targets (revoke,
multiInstance, ...) in a new build using fingerprints taken from a build whose
offsets are already known (any version present in config.json).

Usage:

  # 1. fingerprint a reference build (patched or unpatched both work):
  python3 tools/locate.py fingerprint \
      --binary /Applications/WeChat.app/Contents/MacOS/WeChat \
      --version 32288 --config config.json --output fp-32288.json

  # 2. locate the same functions in a newer build:
  python3 tools/locate.py locate \
      --binary /tmp/new/WeChat.app/Contents/MacOS/WeChat \
      --fingerprint fp-32288.json

Candidate strategies, most reliable first:
  A. body search   - reference function body bytes (entry+8 .. entry+0x200)
                     searched verbatim in the target text, 4-byte aligned.
  B. caller window - normalized instruction window (immediates of adrp/add/
                     mov-imm/bl masked out) ending at each caller, searched in
                     the target; the real BL at the match then reveals the
                     candidate entry.
  C. refcount      - BL reference count of the candidate must match the
                     reference (e.g. multiInstance has exactly 1 caller,
                     revoke has 5 in 32288).

Candidates from A/B that also pass C are strong. Always verify by
disassembling the candidate (objdump -d --start-address ...) and doing a
sandbox launch test before committing a new config.json entry.

Stdlib only. The BL scan over a ~134MB arm64 slice takes roughly a minute.
"""

import argparse
import json
import struct
import sys

CPU_TYPE_ARM64 = 0x0100000C
LC_SEGMENT_64 = 0x19
BODY_SIZE = 0x200          # bytes of function body kept as fingerprint
WINDOW_INSTRUCTIONS = 24   # caller-window size, in instructions


class MachO:
    """Minimal Mach-O reader for one architecture of a fat/thin binary."""

    def __init__(self, path, cpu=CPU_TYPE_ARM64):
        with open(path, "rb") as f:
            self.data = f.read()

        magic, = struct.unpack_from("<I", self.data, 0)
        if magic == 0xFEEDFACF:  # MH_MAGIC_64, thin
            cputype, = struct.unpack_from("<I", self.data, 4)
            if cputype != cpu:
                raise SystemExit("thin binary is not arm64 (cputype=%#x)" % cputype)
            self.slice_off = 0
        else:
            nfat, = struct.unpack_from(">I", self.data, 4)
            for i in range(nfat):
                # fat_arch: cputype(4) cpusubtype(4) offset(4) size(4) align(4)
                cputype, _, off = struct.unpack_from(">III", self.data, 8 + 20 * i)
                if cputype == cpu:
                    self.slice_off = off
                    break
            else:
                raise SystemExit("arm64 slice not found in fat binary")

        base = self.slice_off
        _, _, _, _, ncmds = struct.unpack_from("<IiiII", self.data, base)
        self.segments = []
        pos = base + 32
        for _ in range(ncmds):
            cmd, cmdsize = struct.unpack_from("<II", self.data, pos)
            if cmd == LC_SEGMENT_64:
                segname = self.data[pos + 8:pos + 24].rstrip(b"\0").decode()
                vmaddr, vmsize, fileoff, filesize = struct.unpack_from("<QQQQ", self.data, pos + 24)
                self.segments.append({
                    "name": segname, "vm": vmaddr, "vmsize": vmsize,
                    "fileoff": fileoff, "filesize": filesize,
                })
            pos += cmdsize

        self.text = self.seg("__TEXT")

    def seg(self, name):
        for s in self.segments:
            if s["name"] == name:
                return s
        raise SystemExit("segment %s not found" % name)

    def va2off(self, va):
        for s in self.segments:
            if s["vm"] <= va < s["vm"] + s["vmsize"]:
                return self.slice_off + s["fileoff"] + (va - s["vm"])
        return None


def text_words(m):
    """All words of the arm64 __TEXT slice as a tuple."""
    t = m.text
    off, size = m.slice_off + t["fileoff"], t["filesize"]
    n = size // 4
    return struct.unpack_from("<%dI" % n, m.data, off), t["vm"]


def bl_xrefs(words, text_vm):
    """Map BL target VA -> [caller VA, ...]."""
    xrefs = {}
    for i, w in enumerate(words):
        if (w >> 26) == 0b100101:  # BL
            imm = w & 0x3FFFFFF
            if imm & 0x2000000:
                imm -= 0x4000000
            va = text_vm + i * 4
            xrefs.setdefault(va + imm * 4, []).append(va)
    return xrefs


def mask(w):
    """Normalize an instruction: keep opcode class and registers, zero
    immediates so small codegen changes do not break window matching."""
    if (w & 0x9F000000) == 0x90000000:            # adrp
        return w & 0x9F00001F
    if (w & 0x1F800000) == 0x12800000:            # movz/movn/movk
        return w & 0xFFE0001F
    if (w & 0x0B000000) == 0x11000000:            # add/sub imm
        return w & 0xFFC003FF
    if (w >> 26) in (0b000101, 0b100101):         # b / bl
        return w & 0xFC000000
    return w


def mask_words(data, offset, count):
    return b"".join(
        mask(w).to_bytes(4, "little")
        for w in struct.unpack_from("<%dI" % count, data, offset)
    )


def do_fingerprint(args):
    configs = json.load(open(args.config))
    entry = next((c for c in configs if c["version"] == args.version), None)
    if entry is None:
        raise SystemExit("version %s not in %s" % (args.version, args.config))

    m = MachO(args.binary)
    words, text_vm = text_words(m)
    xrefs = bl_xrefs(words, text_vm)

    fingerprints = []
    for target in entry["targets"]:
        for e in target["entries"]:
            if e["arch"] != "arm64":
                print("skip %s/%s (%s)" % (target["identifier"], e["arch"], e["arch"]),
                      file=sys.stderr)
                continue
            va = int(e["addr"], 16)
            off = m.va2off(va)
            if off is None:
                raise SystemExit("VA %#x not mapped in reference binary" % va)
            callers = xrefs.get(va, [])
            windows = []
            for c in callers:
                co = m.va2off(c)
                windows.append(mask_words(m.data, co - (WINDOW_INSTRUCTIONS - 1) * 4,
                                          WINDOW_INSTRUCTIONS).hex())
            fingerprints.append({
                "identifier": target["identifier"],
                "arch": "arm64",
                "va": "%x" % va,
                "refcount": len(callers),
                "callers": ["%x" % c for c in callers],
                "body": m.data[off + 8:off + BODY_SIZE].hex(),
                "caller_windows": windows,
            })
            print("fingerprinted %-16s va=%#x refcount=%d" % (
                target["identifier"], va, len(callers)))

    with open(args.output, "w") as f:
        json.dump(fingerprints, f, indent=2)
    print("wrote %s" % args.output)


def do_locate(args):
    m = MachO(args.binary)
    words, text_vm = text_words(m)
    xrefs = bl_xrefs(words, text_vm)
    fingerprints = json.load(open(args.fingerprint))

    # masked text of the target, built once
    n = len(words)
    masked = bytearray(n * 4)
    for i, w in enumerate(words):
        masked[i * 4:i * 4 + 4] = mask(w).to_bytes(4, "little")
    text_off = m.slice_off + m.text["fileoff"]
    text_size = m.text["filesize"]

    for item in fingerprints:
        va_candidates = {}  # candidate VA -> evidence list

        def add_candidate(va, method):
            if m.va2off(va) is not None and va % 4 == 0:
                va_candidates.setdefault(va, []).append(method)

        # A: verbatim body search (body starts at entry+8)
        body = bytes.fromhex(item["body"])
        pos = text_off
        while True:
            idx = m.data.find(body, pos, text_off + text_size)
            if idx < 0:
                break
            if idx % 4 == 0:
                add_candidate(text_vm + idx - 8 - text_off, "body")
            pos = idx + 4

        # B: masked caller windows -> real BL at the match reveals the entry
        for win_hex in item["caller_windows"]:
            pat = bytes.fromhex(win_hex)
            pos = 0
            while True:
                idx = masked.find(pat, pos)
                if idx < 0:
                    break
                if idx % 4 == 0:
                    bl_index = idx // 4 + WINDOW_INSTRUCTIONS - 1
                    w = words[bl_index]
                    if (w >> 26) == 0b100101:
                        imm = w & 0x3FFFFFF
                        if imm & 0x2000000:
                            imm -= 0x4000000
                        add_candidate(text_vm + bl_index * 4 + imm * 4, "window")
                pos = idx + 4

        # C: refcount agreement
        scored = []
        for va, evidence in sorted(va_candidates.items()):
            refcount = len(xrefs.get(va, []))
            match = "OK" if refcount == item["refcount"] else "MISMATCH (got %d)" % refcount
            scored.append((va, evidence, refcount, match))

        print("\n=== %s (reference va=%s, refcount=%d) ===" % (
            item["identifier"], item["va"], item["refcount"]))
        if not scored:
            print("  no candidates found - structure changed, manual analysis needed")
            continue
        for va, evidence, refcount, match in scored:
            print("  candidate %#x  methods=%s  refcount=%d %s" % (
                va, "+".join(evidence), refcount, match))
        strong = [s for s in scored if s[3] == "OK" and ("body" in s[1] or "window" in s[1])]
        if strong:
            print("  => best: %#x" % strong[0][0])
        else:
            print("  => no strong candidate, verify manually")


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("fingerprint", help="extract function fingerprints from a reference build")
    p.add_argument("--binary", required=True, help="path to WeChat Mach-O (Contents/MacOS/WeChat)")
    p.add_argument("--version", required=True, help="reference CFBundleVersion present in config.json")
    p.add_argument("--config", default="config.json", help="path to config.json")
    p.add_argument("--output", required=True, help="output fingerprint JSON path")
    p.set_defaults(func=do_fingerprint)

    p = sub.add_parser("locate", help="locate fingerprinted functions in a new build")
    p.add_argument("--binary", required=True, help="path to the new WeChat Mach-O")
    p.add_argument("--fingerprint", required=True, help="fingerprint JSON from step 1")
    p.set_defaults(func=do_locate)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
