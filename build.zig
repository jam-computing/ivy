const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ivy = b.addExecutable(.{
        .name = "ivy",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zap = b.dependency("zap", .{
        .target = target,
        .optimize = optimize,
        .openssl = false,
    });

    const sd = b.dependency("stardust", .{
        .target = target,
        .optimize = optimize,
    });

    ivy.linkSystemLibrary("mariadb");
    ivy.linkSystemLibrary("ws2811");
    ivy.root_module.addImport("zap", zap.module("zap"));
    ivy.root_module.addImport("stardust", sd.module("stardust"));

    b.installArtifact(ivy);
    const run_cmd = b.addRunArtifact(ivy);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
