#include <stdio.h>
#include <stdlib.h>
#include <execinfo.h>
#include <unistd.h>
#include <dlfcn.h>
#include <sys/socket.h>

static void bt_short(const char* tag) {
    void* frames[24];
    int n = backtrace(frames, 24);
    fprintf(stderr, "[probe2] %s (%d frames)\n", tag, n);
    for (int i = 0; i < n && i < 14; i++) {
        Dl_info info;
        if (dladdr(frames[i], &info) && info.dli_fname && info.dli_fname[0])
            fprintf(stderr, "[probe2] f%02d %s+0x%lx\n", i, info.dli_fname,
                    (unsigned long)((char*)frames[i] - (char*)info.dli_saddr));
    }
}

static int my_connect(int s, const struct sockaddr* a, int l) {
    static int depth = 0;
    if (!depth) { depth = 1; bt_short("connect"); depth = 0; }
    return connect(s, a, l);
}

static ssize_t my_sendto(int s, const void* b, size_t n, int f, const struct sockaddr* a, int l) {
    static int depth = 0;
    if (!depth) { depth = 1; bt_short("sendto"); depth = 0; }
    return sendto(s, b, n, f, a, l);
}

static void my_exit(int c) { fprintf(stderr, "[probe2] exit(%d)\n", c); _exit(c); }

__attribute__((used)) static struct { const void* r; const void* o; } i1
    __attribute__((section("__DATA_CONST,__interpose"))) = { (const void*)my_connect, (const void*)connect };
__attribute__((used)) static struct { const void* r; const void* o; } i2
    __attribute__((section("__DATA_CONST,__interpose"))) = { (const void*)my_sendto, (const void*)sendto };
__attribute__((used)) static struct { const void* r; const void* o; } i3
    __attribute__((section("__DATA_CONST,__interpose"))) = { (const void*)my_exit, (const void*)exit };
