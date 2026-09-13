# WeChat 269602 arm64 patch findings

This note records the evidence used to identify the two patch targets in
`Contents/Resources/wechat.dylib` for WeChat 4.1.13 (`CFBundleVersion=269602`).
Addresses are virtual addresses in the arm64 dylib. Its `__TEXT` segment has
`vmaddr=0` and `fileoff=0`, so these VAs are also offsets in a thin arm64
slice. The inspected slice matches the currently installed application:

```text
SHA-256 413c124643903640946836d631fb4185133a8ffccbf2863e77b9a4b70568abd6
```

## Final targets

| target | VA | original first 8 bytes | patch bytes | result |
|---|---:|---|---|---|
| revoke | `0x44de938` | `F44FBEA9FD7B01A9` | `00008052C0035FD6` (`mov w0,#0; ret`) | classify every message as not being `revokemsg`, which short-circuits revoke handling |
| multiInstance | `0x27370c` | `FF0306D1FC6F14A9` | `20008052C0035FD6` (`mov w0,#1; ret`) | make the complete single-instance predicate report success |

Always verify the version, architecture, original bytes, and target segment
before writing either patch. A version match alone is not sufficient if the
application was partially updated or repackaged.

## Revoke evidence

The old 32288 function at `0x103db34c0` and the new function at `0x44de938`
have the same implementation shape. In 32288 the configured entry had already
been replaced by an 8-byte return stub, while its original implementation
started at entry `+8`; in 269602 the implementation starts directly at the
function entry.

The new function constructs the literal `revokemsg` from eight source bytes
`revokems` plus the immediate byte `0x67`, compares its input string with that
literal, and returns the equality result. It has nine direct callers. One of
them is the 80-byte predicate at `0x494f4f8`:

```text
0x494f508  add x0, x0, #0x1a8
0x494f50c  bl  0x44de938
0x494f510  cbz w0, 0x494f53c
...
0x494f538  cset w0, hi
```

The corresponding 32288 predicate is at `0x1041c9644`; it has the same control
flow and virtual call, with only structure offsets and callee addresses moved.
Returning zero from `0x44de938` therefore takes the predicate's early false
path before the revoke time-window logic. This confirms that the configured
zero return implements anti-revoke behavior rather than enabling revocation.

Static evidence establishes the classification and control-flow semantics.
The patch was also written to a clone and passed
`codesign --verify --deep --strict`. End-to-end message retention still needs
a logged-in two-account revoke test.

## Multi-instance evidence

The old 32288 startup function is `0x100224e50`; the corresponding 269602
startup function is `0x2a8e44`. Instruction-sequence alignment shows that the
old block containing the constant-return function `0x1001e1a74` was removed:

```text
32288:  cleanup argv -> call 0x1001e1a74 -> conditional exit
        -> singleton accessor/init -> mov w0,#2 -> next startup stage

269602: cleanup argv ---------------------------------> mov w0,#2
        -> next startup stage
```

The instructions before and after the removed block align continuously. Thus
there is no valid one-to-one constant-return candidate in the new binary. The
29 `movz w0,#imm; ret` candidates listed in `candidates-269602.txt` are a
heuristic set, not evidence of the new multi-instance target. Patching every
candidate with a corrected probe left the same-id clone exiting with status
255.

The new single-instance predicate is `0x27370c` (820 bytes, one direct caller):

1. `0x2a9d90` calls `0x27370c`, saves the result in `w20`, and branches to the
   `-1` return path when it is false.
2. `0x27370c` first calls `0x4377a9c`, a function that builds and operates on
   `lock` / `lock.ini`. Failure produces a false result.
3. On lock success, chained-fixup selector references decode to
   `mainBundle`, `bundleIdentifier`,
   `runningApplicationsWithBundleIdentifier:`, and `count`.
4. If the running-application count is less than two, the predicate returns
   true. If it is at least two, it obtains `firstObject`, calls
   `activateWithOptions:` with option `2`, and returns false.

This function is self-contained single-instance policy and notification logic;
it is not general application initialization. Replacing the complete predicate
with `mov w0,#1; ret` matches the intent and shape of the historical patch while
avoiding partial bypasses of its lock and AppKit branches.

Dynamic validation used an injected in-memory patch against a same-bundle-id
clone while another WeChat instance was running. The unmodified baseline and
all 29 constant-return candidates exited with status 255. With `0x27370c`
patched to return one, the second instance remained alive for more than 12
seconds. This proves the launch gate on the tested arm64 build. It does not by
itself prove long-session behavior, login isolation, or concurrent writes to
the same account data; those remain regression-test boundaries.

The final on-disk two-target patch was separately launched without any injected
library. The original installed process and the patched clone coexisted for
at least 60 seconds; both target byte sequences, the original backup hash,
and the strict deep code signature were verified.

## Corrected probe assumptions

The original `probe5.c` used `20 00 00 52` while labeling it
`mov w0,#1`. The correct arm64 encoding is `20 00 80 52`. Results from the old
probe are invalid. A reliable dynamic trial must also confirm that the target
image callback ran, that memory protection and the write succeeded, and that
the bytes read back correctly. Process survival alone is not proof that a
candidate was patched.

The custom loader reports the dylib more than once during loading; the first
memory-protection attempt may fail and a later image callback may succeed.
Trials must record the successful patch event before interpreting the exit
status.

## Risk and rollback

The revoke patch affects message-type classification globally, so malformed or
new revoke message variants may follow a different path. The multi-instance
patch bypasses both lock-file and running-application checks; concurrent use of
the same account or shared data directory may expose upstream assumptions that
the application normally prevents. Test two login windows, message send and
receive, clean quit, relaunch, and database health before treating it as fully
validated.

Keep an untouched backup of the original `wechat.dylib`. Roll back by quitting
all WeChat instances, restoring the exact original dylib, ad-hoc signing the
application again, and verifying the signature. The original-byte checks in
the table can detect the unpatched 269602 arm64 slice but are not a substitute
for a full-file backup.
