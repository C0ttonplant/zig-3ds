const std = @import("std");
const builtin = @import("builtin");

const emulator = "citra";
const flags = .{"-lctru"};
const devkitpro = "/opt/devkitpro";

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const resolved = b.standardTargetOptions(.{.default_target = .{ 
        .cpu_arch = .arm,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.mpcore },
    }});

    const exe = b.addExecutable(.{
        .name = "3ds-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = resolved,
        .optimize = optimize,
    });

    exe.linkLibC();

    exe.setLibCFile(b.path("libc.txt"));

    exe.addIncludePath(.{ .cwd_relative =  devkitpro ++ "/libctru/include"});
    exe.addIncludePath(.{ .cwd_relative =  devkitpro ++ "/portlibs/3ds/include"});


    // obj.setBuildMode(mode);

    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const elf = b.addSystemCommand(&(.{
        devkitpro ++ "/devkitARM/bin/arm-none-eabi-gcc" ++ extension,
        "-g",
        "-march=armv6k",
        "-mtune=mpcore",
        "-mfloat-abi=hard",
        "-mtp=soft",
        "-Wl,-Map,zig-out/zig-3ds.map",
        "-specs=" ++ devkitpro ++ "/devkitARM/arm-none-eabi/lib/3dsx.specs",
        "zig-out/zig-3ds.o",
        "-L" ++ devkitpro ++ "/libctru/lib",
        "-L" ++ devkitpro ++ "/portlibs/3ds/lib",
    } ++ flags ++ .{
        "-o",
        "zig-out/zig-3ds.elf",
    }));

    const dsx = b.addSystemCommand(&.{
        devkitpro ++ "/tools/bin/3dsxtool" ++ extension,
        "zig-out/zig-3ds.elf",
        "zig-out/zig-3ds.3dsx",
    });
    // dsx.stdout_action = .ignore;

    b.installArtifact(exe);
    // elf.create(b, "elf");
    // dsx.create(b, "dsx");

    b.default_step.dependOn(&dsx.step);
    dsx.step.dependOn(&elf.step);
    elf.step.dependOn(&exe.step);

    const run_step = b.step("run", "Run in Citra");
    const citra = b.addSystemCommand(&.{ emulator, "zig-out/zig-3ds.3dsx" });
    // run_step.dependOn(&dsx.step);
    run_step.dependOn(&citra.step);
}
