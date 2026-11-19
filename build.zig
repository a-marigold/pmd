const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const md4zig = b.dependency("md4zig", .{ .target = target, .optimize = optimize });
    const md4zig_mod = md4zig.module("md4zig");

    const main_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "md4zig", .module = md4zig_mod },
        },
    });

    const exe = b.addExecutable(.{ .name = "pmd", .root_module = main_mod });

    b.installArtifact(exe);

    const check_step = b.step("check", "Build on save");

    check_step.dependOn(&exe.step);
}
