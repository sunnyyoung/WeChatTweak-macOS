import struct, sys
sys.path.insert(0, "/Users/ztf1104/Documents/yunsu/WeChatTweak/tools")
from locate import MachO

def uleb(data, pos):
    r, s = 0, 0
    while True:
        b = data[pos]; pos += 1
        r |= (b & 0x7F) << s
        if not b & 0x80: return r, pos
        s += 7

def function_starts(m):
    """Function start VAs from LC_FUNCTION_STARTS."""
    base = m.slice_off
    _, _, _, _, ncmds = struct.unpack_from("<IiiII", m.data, base)
    pos = base + 32
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", m.data, pos)
        if cmd == 0x26:  # LC_FUNCTION_STARTS
            dataoff, datasize = struct.unpack_from("<II", m.data, pos + 8)
            blob = m.data[base + dataoff: base + dataoff + datasize]
            p, acc, starts = 0, 0, []
            while p < len(blob):
                d, p = uleb(blob, p)
                acc += d
                starts.append(acc)
            t = m.text
            return [t["vm"] + s for s in starts]
        pos += cmdsize
    return []

def cstring_at(m, va, maxlen=100):
    t = m.text
    if not (t["vm"] <= va < t["vm"] + t["filesize"]):
        return None
    o = m.slice_off + t["fileoff"] + (va - t["vm"])
    end = m.data.find(b"\0", o, o + maxlen)
    if end < 0: return None
    s = m.data[o:end]
    try: txt = s.decode("ascii")
    except: return None
    return txt if len(txt) >= 4 and all(31 < ord(c) < 127 for c in txt) else None

class FuncGraph:
    def __init__(self, m):
        self.m = m
        self.starts = sorted(function_starts(m))
        t = m.text
        n = t["filesize"] // 4
        self.words = struct.unpack_from("<%dI" % n, m.data, m.slice_off + t["fileoff"])
        self.vm = t["vm"]
        self.xrefs = {}
        for i, w in enumerate(self.words):
            if (w >> 26) == 0b100101:
                imm = w & 0x3FFFFFF
                if imm & 0x2000000: imm -= 0x4000000
                va = self.vm + i * 4
                self.xrefs.setdefault(va + imm * 4, []).append(va)

    def containing(self, va):
        import bisect
        i = bisect.bisect_right(self.starts, va) - 1
        if i < 0: return None
        start = self.starts[i]
        end = self.starts[i + 1] if i + 1 < len(self.starts) else self.vm + len(self.words) * 4
        if not (start <= va < end): return None
        return (start, end)

    def analyze(self, lo, hi):
        """strings + callees of function range."""
        i0, i1 = (lo - self.vm) // 4, (hi - self.vm) // 4
        regs, strings, callees = {}, [], []
        for i in range(i0, i1):
            w, va = self.words[i], self.vm + i * 4
            if (w & 0x9F000000) == 0x90000000:
                rd = w & 0x1F
                immlo = (w >> 29) & 3; immhi = (w >> 5) & 0x7FFFF
                imm = (immhi << 2 | immlo) << 12
                if imm & (1 << 32): imm -= (1 << 33)
                regs[rd] = ((va >> 12) << 12) + imm
            elif (w & 0xFF800000) == 0x91000000:
                rd = w & 0x1F; rn = (w >> 5) & 0x1F
                imm = (w >> 10) & 0xFFF
                if rn in regs:
                    s = cstring_at(self.m, regs[rn] + imm)
                    if s: strings.append(s)
            elif (w >> 26) == 0b100101:
                imm = w & 0x3FFFFFF
                if imm & 0x2000000: imm -= 0x4000000
                callees.append(va + imm * 4)
        return strings, callees

if __name__ == "__main__":
    path = sys.argv[1]
    vas = [int(x, 16) for x in sys.argv[2:]]
    m = MachO(path)
    g = FuncGraph(m)
    for va in vas:
        rng = g.containing(va)
        if not rng:
            print("%#x: not in a function" % va); continue
        lo, hi = rng
        strings, callees = g.analyze(lo, hi)
        print("=== site %#x in func [%#x..%#x) size=%d ===" % (va, lo, hi, hi - lo))
        print("  refcount(this func): %d" % len(g.xrefs.get(lo, [])))
        print("  strings: %s" % (strings[:15] if strings else "none"))
        print("  callees: %s" % ["%#x" % c for c in callees[:20]])
