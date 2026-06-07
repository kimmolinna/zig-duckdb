const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const translate_duckdb = b.addTranslateC(.{
        .root_source_file = b.path("duckdb/duckdb.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_duckdb.addIncludePath(b.path("duckdb"));

    const duckdb_mod = translate_duckdb.createModule();
    duckdb_mod.addIncludePath(b.path("duckdb"));
    duckdb_mod.addLibraryPath(b.path("duckdb"));
    duckdb_mod.linkSystemLibrary("duckdb", .{});
    duckdb_mod.addRPath(b.path("duckdb"));

    const exe = b.addExecutable(.{
        .name = "zig-duck",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "duckdb", .module = duckdb_mod },
            },
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const update = b.addSystemCommand(&.{ "bash", "scripts/update-duckdb.sh" });
    const update_step = b.step("update-duckdb", "Download latest DuckDB release artifacts");
    update_step.dependOn(&update.step);
}
