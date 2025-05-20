const std = @import("std");
const builtin = @import("builtin");


const name = "3ds-zig";
const extension = if (builtin.target.os.tag == .windows) ".exe" else "";

pub fn build(b: *std.Build) void {
    const wf = b.addWriteFiles();

    const optimize = b.standardOptimizeOption(.{});
    const resolved = b.standardTargetOptions(.{.default_target = .{ 
        .cpu_arch = .arm,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.mpcore },
    }});

    const exe = b.addObject(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = resolved,
        .optimize = optimize,
    });

    exe.setLibCFile(b.path("libc.txt"));
    exe.linkLibC();

    exe.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "/opt/devkitpro/libctru/include" } });
    exe.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = "/opt/devkitpro/devkitARM/arm-none-eabi/include" } });


    // generate .elf
    const elf = b.addSystemCommand(&(.{ "/opt/devkitpro/devkitARM/bin/arm-none-eabi-gcc" ++ extension }));
    elf.setCwd(wf.getDirectory());
    elf.addArgs(&.{ "-specs=3dsx.specs", "-g", "-march=armv6k", "-mtune=mpcore", "-mfloat-abi=hard", "-mtp=soft" });
    _ = elf.addPrefixedOutputFileArg("-Wl,-Map,", name++".map");

    elf.addArtifactArg(exe);

    elf.addArgs(&.{ "-L/opt/devkitpro/libctru/lib", "-lctru" });
    const out_elf = elf.addPrefixedOutputFileArg("-o", name++".elf");

    // generate .sdmh
    const smdh = b.addSystemCommand(&.{"/opt/devkitpro/tools/bin/smdhtool"});
    smdh.setCwd(wf.getDirectory());
    smdh.addArgs(&.{ "--create", name, "Built with Zig, devkitARM, and libctru", "cottonplant", "/opt/devkitpro/libctru/default_icon.png" });
    const out_smdh = smdh.addOutputFileArg(name++".smdh");

    // generate final .3dsx
    const dsx = b.addSystemCommand(&.{"/opt/devkitpro/tools/bin/3dsxtool" ++ extension});
    dsx.setCwd(wf.getDirectory());
    dsx.addFileArg(out_elf);
    const out_dsx = dsx.addOutputFileArg(name++".3dsx");
    dsx.addPrefixedFileArg("--smdh=", out_smdh);


    const install_3dsx = b.addInstallFileWithDir(out_dsx, .prefix, name++".3dsx");
    b.getInstallStep().dependOn(&install_3dsx.step);
}