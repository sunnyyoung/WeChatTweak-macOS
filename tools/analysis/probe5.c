// Development probe; use only with a disposable, ad-hoc signed app copy.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>

static void image_added(const struct mach_header* header, intptr_t slide) {
    Dl_info info;
    if (!dladdr(header, &info) || !info.dli_fname ||
        !strstr(info.dli_fname, "/wechat.dylib")) return;
    const char* address = getenv("WECHAT_PATCH_ADDR");
    if (!address) return;
    char* end;
    unsigned long candidate = strtoul(address, &end, 16);
    if (*end || !candidate || candidate % 4) return;
    if (header->magic != MH_MAGIC_64) return;
    const struct mach_header_64* h = (const void*)header;
    const struct load_command* command = (const void*)(h + 1);
    int in_code = 0;
    for (uint32_t i = 0; i < h->ncmds; ++i) {
        if (command->cmd == LC_SEGMENT_64) {
            const struct segment_command_64* segment = (const void*)command;
            const struct section_64* section = (const void*)(segment + 1);
            for (uint32_t j = 0; j < segment->nsects; ++j) {
                if (!strncmp(section[j].sectname, "__text", 16) &&
                    candidate >= section[j].addr && section[j].size >= 8 &&
                    candidate - section[j].addr <= section[j].size - 8) in_code = 1;
            }
        }
        command = (const void*)((const char*)command + command->cmdsize);
    }
    if (!in_code) return;
    unsigned char bytes[] = {0x20, 0x00, 0x80, 0x52, 0xc0, 0x03, 0x5f, 0xd6};
    if (getenv("WECHAT_PATCH_ZERO")) bytes[0] = 0;
    void* target = (void*)(slide + candidate);
    size_t pagesize = getpagesize();
    uintptr_t page = (uintptr_t)target & ~(pagesize - 1);
    kern_return_t result = vm_protect(mach_task_self(), page, pagesize, FALSE,
        VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (result != KERN_SUCCESS) {
        fprintf(stderr, "[probe5] pid=%d protect failed: %d\n", getpid(), result);
        return;
    }
    memcpy(target, bytes, sizeof(bytes));
    sys_icache_invalidate(target, sizeof(bytes));
    result = vm_protect(mach_task_self(), page, pagesize, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    fprintf(stderr, "[probe5] pid=%d patched %#lx; restore=%d; bytes=%02x%02x%02x%02x\n",
        getpid(), candidate, result, bytes[0], bytes[1], bytes[2], bytes[3]);
}

__attribute__((constructor)) static void ctor(void) {
    fprintf(stderr, "[probe5] loaded pid=%d\n", getpid());
    _dyld_register_func_for_add_image(image_added);
}
