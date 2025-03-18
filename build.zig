const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dep_opts = .{ .target = target, .optimize = optimize };

    const exe = b.addExecutable(.{
        .name = "datastar_zig_train",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const httpz = b.dependency("httpz", dep_opts).module("httpz");
    exe.root_module.addImport("httpz", httpz);

    // const datastar = b.dependency("datastar", .{
    //     .target = target,
    //     .optimize = optimize,
    //     // .framework = .httpz, // or .tokamak
    // }).module("datastar");
    // exe.root_module.addImport("datastar", datastar);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
