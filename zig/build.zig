const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const skip_gen_days = b.option(bool, "skip-gen-days", "Skip generating generated_days.zig") orelse false;

    if (!skip_gen_days) {
        _ = genDaysFile(b) catch @panic("failed to generate days file");
    }

    const mecha = b.dependency("mecha", .{});

    const mod = b.addModule("aocLib", .{
        .root_source_file = b.path("src/lib/root.zig"),
        .target = target,
    });

    mod.addImport("mecha", mecha.module("mecha"));

    mod.addImport("aocLib", mod);

    const exe = b.addExecutable(.{
        .name = "aoc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "aocLib", .module = mod },
            },
        }),
    });

    const exe_check = b.addExecutable(.{
        .name = "foo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "aocLib", .module = mod },
            },
        }),
    });

    // Finally we add the "check" step which will be detected
    // by ZLS and automatically enable Build-On-Save.
    // If you copy this into your `build.zig`, make sure to rename 'foo'
    const check = b.step("check", "Check if foo compiles");
    check.dependOn(&exe_check.step);

    const clap = b.dependency("clap", .{});
    exe.root_module.addImport("clap", clap.module("clap"));
    exe_check.root_module.addImport("clap", clap.module("clap"));

    exe.root_module.addImport("mecha", mecha.module("mecha"));
    exe_check.root_module.addImport("mecha", mecha.module("mecha"));

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}

fn genDaysFile(b: *std.Build) !std.Build.LazyPath {
    var buf = std.ArrayList(u8).empty;
    defer buf.deinit(b.allocator);
    const w = buf.writer(b.allocator);
    try w.writeAll("pub const days = .{\n");

    var names = std.ArrayList([]const u8).empty;
    defer {
        for (names.items) |name| {
            b.allocator.free(name);
        }
        names.deinit(b.allocator);
    }

    var dir = try std.fs.cwd().openDir("src/lib", .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != .directory) continue;
        if (entry.name.len != 5) continue;
        if (!std.mem.startsWith(u8, entry.name, "day")) continue;
        const num = std.fmt.parseInt(u8, entry.name[3..], 10) catch continue;
        if (num == 0) continue;
        try names.append(b.allocator, try b.allocator.dupe(u8, entry.name));
    }

    // Keep deterministic ordering.
    std.mem.sort([]const u8, names.items, {}, struct {
        fn lessThan(_: void, first: []const u8, second: []const u8) bool {
            return std.mem.lessThan(u8, first, second);
        }
    }.lessThan);

    for (names.items) |name| {
        // Store days keyed by the zero-padded day number (e.g. "01") instead of "day01".
        try w.print("    .{{ \"{s}\", @import(\"{s}/day.zig\").day }},\n", .{ name[3..], name });
    }

    try w.writeAll("};\n");

    const out_path = b.pathFromRoot("src/lib/generated_days.zig");
    defer b.allocator.free(out_path);

    // Write alongside the rest of the library so relative imports stay inside the module path.
    var f = try std.fs.createFileAbsolute(out_path, .{ .truncate = true });
    defer f.close();
    try f.writeAll(buf.items);

    return b.path("src/lib/generated_days.zig");
}
