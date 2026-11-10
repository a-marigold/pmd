const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{ .name = "pmd", .root_module = mod });

    b.installArtifact(exe);

    const check_step = b.step("check", "Build on save");

    check_step.dependOn(&exe.step);
}
