const ds = @import("3ds/c.zig");
const std = @import("std");

export fn main() void {
    ds.gfxInitDefault();
    defer ds.gfxExit();

    _ = ds.consoleInit(ds.GFX_TOP, null);
    _ = ds.printf("\x1b[16;20HHello World!");
    _ = ds.printf("\x1b[30;16HPress Start to exit.\n");

    // ds.timer_create(clock_id: clockid_t, noalias evp: [*c]struct_sigevent, noalias timerid: [*c]timer_t)
    while (ds.aptMainLoop()) {
        ds.hidScanInput();

        const kDown = ds.hidKeysDown();

        if (kDown & ds.KEY_START > 0) break;


        ds.gfxFlushBuffers();
        ds.gfxSwapBuffers();
        ds.gspWaitForEvent(ds.GSPGPU_EVENT_VBlank0, true);
    }
}