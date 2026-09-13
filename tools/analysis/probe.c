#include <stdio.h>
#include <stdlib.h>
#include <execinfo.h>
#include <unistd.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>

static void report(const char* who) {
    void* frames[48];
    int n = backtrace(frames, 48);
    fprintf(stderr, "[probe] %s() called, %d frames, main slide=%p\n", who, n,
            (void*)_dyld_get_image_vmaddr_slide(0));
    for (int i = 0; i < n; i++) {
        Dl_info info;
        if (dladdr(frames[i], &info) && info.dli_fname)
            fprintf(stderr, "[probe] f%02d %s+0x%lx  (%p)\n", i,
                    info.dli_fname, (unsigned long)((char*)frames[i] - (char*)info.dli_saddr), frames[i]);
        else
            fprintf(stderr, "[probe] f%02d %p\n", i, frames[i]);
    }
    fsync(2);
}

#define INTERPOSE(name) \
    static void my_##name(int c) { report(#name); _exit(c); } \
    __attribute__((used)) static struct { const void* repl; const void* orig; } inter_##name \
    __attribute__((section("__DATA_CONST,__interpose"))) = { (const void*)my_##name, (const void*)name };

INTERPOSE(exit)
INTERPOSE(_Exit)
INTERPOSE(abort)
