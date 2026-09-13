import struct, sys
sys.path.insert(0, "/Users/ztf1104/Documents/yunsu/WeChatTweak/tools")
sys.path.insert(0, "/tmp/wecomtweak")
from locate import MachO
from funcgraph import FuncGraph

m = MachO("/tmp/wecomtweak/WeChat_arm64")
g = FuncGraph(m)
lo, hi = 0x103daf000, 0x103db6000
import bisect
i0 = bisect.bisect_left(g.starts, lo); i1 = bisect.bisect_left(g.starts, hi)
for s in g.starts[i0:i1]:
    end = g.starts[g.starts.index(s)+1] if g.starts.index(s)+1 < len(g.starts) else hi
    strings, callees = g.analyze(s, end)
    if strings:
        print("func %#x size=%d strings=%s" % (s, end-s, strings[:8]))
