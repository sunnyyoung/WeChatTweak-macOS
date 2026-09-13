import struct, sys
sys.path.insert(0, "/Users/ztf1104/Documents/yunsu/WeChatTweak/tools")
sys.path.insert(0, "/tmp/wecomtweak")
from locate import MachO
from funcgraph import FuncGraph

def mask_word(w):
    if (w & 0x9F000000) == 0x90000000:   # adrp
        return w & 0x9F00001F
    if (w >> 26) in (0b000101, 0b100101):  # b / bl
        return w & 0xFC000000
    if (w & 0xFF800000) in (0x91000000, 0x11000000):  # add/sub imm
        return w & 0xFFC003FF
    if (w & 0xFFC00000) in (0x34000000, 0x35000000, 0x36000000, 0x37000000,
                            0xB4000000, 0xB5000000, 0xB6000000, 0xB7000000):  # cbz/cbnz/tbz/tbnz
        return w & 0xFFF8001F
    if (w & 0xBF000000) in (0x08000000 | 0x39000000,) or (w & 0x3B000000) == 0x39000000:
        pass
    if (w & 0x3B000000) == 0x38000000:   # ldr/str imm unsigned
        return w & 0xFFC00000
    return w

def ref_bytes(path, lo, hi, mask_ldr_imm=False):
    m = MachO(path)
    off = m.va2off(lo)
    n = (hi - lo) // 4
    words = struct.unpack_from("<%dI" % n, m.data, off)
    return b"".join(mask_word(w).to_bytes(4, "little") for w in words), m

def search(path, pattern):
    m = MachO(path)
    t = m.text
    # mask the whole text once
    n = t["filesize"] // 4
    words = struct.unpack_from("<%dI" % n, m.data, m.slice_off + t["fileoff"])
    masked = b"".join(mask_word(w).to_bytes(4, "little") for w in words)
    print("  text=%#x bytes, searching %d-byte pattern..." % (t["filesize"], len(pattern)))
    hits, pos = [], 0
    while True:
        i = masked.find(pattern, pos)
        if i < 0: break
        if i % 4 == 0:
            hits.append(t["vm"] + i)
        pos = i + 4
    return hits, words, t["vm"]

# --- revoke thunk from 32288: 0x1041c9644 .. 0x1041c96a4 ---
REF = "/tmp/wecomtweak/WeChat_arm64"
TGT = "/tmp/wecomtweak/wechat_arm64.dylib"
pat, _ = ref_bytes(REF, 0x1041c9644, 0x1041c96a4)
print("thunk pattern ready (%d instrs)" % (len(pat)//4))
hits, words, vm = search(TGT, pat)
print("masked byte-search hits:", ["%#x" % h for h in hits])

# --- multiInstance call-site window: 0x100225f94 .. 0x100225fbc ---
pat2, _ = ref_bytes(REF, 0x100225f94, 0x100225fbc)
hits2, _, _ = search(TGT, pat2)
print("call-site window hits:", ["%#x" % h for h in hits2])
for h in hits2:
    # BL is the 2nd instruction of the window; decode real target from unmasked words
    idx = (h - vm) // 4 + 1
    w = words[idx]
    if (w >> 26) == 0b100101:
        imm = w & 0x3FFFFFF
        if imm & 0x2000000: imm -= 0x4000000
        print("  at %#x -> multiInstance candidate %#x" % (h, vm + idx*4 + imm*4))
