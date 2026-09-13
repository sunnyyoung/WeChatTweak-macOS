import struct, sys
sys.path.insert(0, "/Users/ztf1104/Documents/yunsu/WeChatTweak/tools")
from locate import MachO

def find_strings(m, needles):
    """VA of each needle (NUL-terminated) in __TEXT."""
    t = m.text
    base = m.slice_off + t["fileoff"]
    out = {}
    for nd in needles:
        pat = nd.encode() + b"\0"
        pos, vas = base, []
        while True:
            i = m.data.find(pat, pos, base + t["filesize"])
            if i < 0: break
            vas.append(t["vm"] + (i - base))
            pos = i + 1
        out[nd] = vas
    return out

def adrp_add_xrefs(m, targets):
    """Scan text for adrp+add pairs whose computed VA is in targets."""
    t = m.text
    off = m.slice_off + t["fileoff"]
    vm = t["vm"]
    n = t["filesize"] // 4
    words = struct.unpack_from("<%dI" % n, m.data, off)
    hits = {}  # target va -> [site va]
    regs = {}
    last_adrp_idx = {}
    for i, w in enumerate(words):
        va = vm + i * 4
        if (w & 0x9F000000) == 0x90000000:  # adrp
            rd = w & 0x1F
            immlo = (w >> 29) & 3
            immhi = (w >> 5) & 0x7FFFF
            imm = (immhi << 2 | immlo) << 12
            if imm & (1 << 32): imm -= (1 << 33)
            regs[rd] = ((va >> 12) << 12) + imm
            last_adrp_idx[rd] = i
        elif (w & 0xFF800000) == 0x91000000:  # add imm
            rd = w & 0x1F; rn = (w >> 5) & 0x1F
            imm = (w >> 10) & 0xFFF
            if rn in regs and i - last_adrp_idx.get(rn, -10**9) <= 8:
                tva = regs[rn] + imm
                if tva in targets:
                    hits.setdefault(tva, []).append(va)
    return hits

if __name__ == "__main__":
    path, *needles = sys.argv[1:]
    m = MachO(path)
    sv = find_strings(m, needles)
    targets = {}
    for nd, vas in sv.items():
        for v in vas: targets[v] = nd
        print("%s: %d occurrence(s) %s" % (nd, len(vas), ["%#x" % v for v in vas[:5]]))
    hits = adrp_add_xrefs(m, set(targets))
    print("--- xrefs ---")
    for tva, sites in sorted(hits.items()):
        print("%s @ %#x <- %s" % (targets[tva], tva, ["%#x" % s for s in sites]))
