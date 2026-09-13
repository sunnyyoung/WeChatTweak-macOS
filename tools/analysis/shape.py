import struct, sys
sys.path.insert(0, "/Users/ztf1104/Documents/yunsu/WeChatTweak/tools")
sys.path.insert(0, "/tmp/wecomtweak")
from locate import MachO
from funcgraph import FuncGraph

def shape_scan(path, sizes=(60,200), refcounts=(2,3,4), vtoff=0x50):
    m = MachO(path)
    g = FuncGraph(m)
    t = m.text
    vm = t["vm"]
    n = t["filesize"] // 4
    words = g.words
    ldr_vt = 0xF9400000 | ((vtoff >> 3) << 10) | (8 << 5) | 8  # ldr x8,[x8,#0x50]
    results = []
    import bisect
    for idx, start in enumerate(g.starts):
        end = g.starts[idx + 1] if idx + 1 < len(g.starts) else vm + n * 4
        size = end - start
        if not (sizes[0] <= size <= sizes[1]): continue
        rc = len(g.xrefs.get(start, []))
        if rc not in refcounts: continue
        i0, i1 = (start - vm) // 4, (end - vm) // 4
        bls, has_vcall, has_cset, has_ret = [], False, False, False
        k = i0
        while k < i1:
            w = words[k]
            if (w >> 26) == 0b100101:
                imm = w & 0x3FFFFFF
                if imm & 0x2000000: imm -= 0x4000000
                bls.append(vm + k*4 + imm*4)
            elif words[k] == ldr_vt and k + 1 < i1 and words[k+1] == (0xD63F0000 | (8 << 5)):
                has_vcall = True
            elif (w & 0x7F8003E0) == 0x1A8003E0:
                has_cset = True
            elif w == 0xD65F03C0:
                has_ret = True
            k += 1
        if has_vcall and has_cset and has_ret and len(bls) == 3:
            results.append((start, size, rc, bls))
    return results

for name, path in [("32288 ref", "/tmp/wecomtweak/WeChat_arm64"),
                   ("269602 dylib", "/tmp/wecomtweak/wechat_arm64.dylib")]:
    print("=== %s ===" % name)
    for start, size, rc, bls in shape_scan(path):
        print("  func %#x size=%d refcount=%d bls=%s" % (start, size, rc, ["%#x" % b for b in bls]))
