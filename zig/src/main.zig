const std = @import("std");
const aocLib = @import("aocLib");
const clap = @import("clap");

const Days = aocLib.Days;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    // Describe CLI with clap’s mini-DSL.
    const params = comptime clap.parseParamsComptime(
        \\-e, --example       Use example input (in.example) instead of in
        \\-h, --help          Show this help message and exit
        \\<str>
        \\<u8>
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = alloc,
    }) catch |err| {
        // Nice error reporting
        try diag.reportToFile(std.fs.File.stderr(), err);
        return err;
    };
    defer res.deinit();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    // Handle --help
    if (res.args.help != 0) {
        return clap.helpToFile(.stderr(), clap.Help, &params, .{});
        // try clap.helpToFile(std.fs.File.stdout(), &params, .{});
        // return;
    }

    // // Positionals come back as strings here: <day> <part>
    // // (we told clap nothing special about their types)
    // const day_str = res.positionals[0];
    // const part_str = res.positionals[1];

    const day_str = res.positionals[0] orelse return error.MissingArg1;
    const part = res.positionals[1] orelse return error.MissingArg1;

    // const part = std.fmt.parseInt(u8, part_str, 10) catch {
    //     try stdout.write("Invalid part '{s}', expected 1 or 2\n", .{part_str});
    //     return error.BadPart;
    // };

    const Day = Days.dayMap.get(day_str) orelse {
        try stdout.print("Unknown day '{s}'\n", .{day_str});
        return error.UnknownDay;
    };

    const filename = if (res.args.example != 0) "in.example" else "in";

    // Absolute path to the executable, e.g. .../your-project/zig-out/bin/aoc
    const exe_path = try std.fs.selfExePathAlloc(alloc);
    defer alloc.free(exe_path);

    // Directory containing the exe, e.g. .../your-project/zig-out/bin
    const exe_dir = std.fs.path.dirname(exe_path) orelse ".";

    // Parent of exe_dir: zig-out
    const zig_out_dir = std.fs.path.dirname(exe_dir) orelse exe_dir;
    // Parent of zig-out: project root
    const project_root = std.fs.path.dirname(zig_out_dir) orelse zig_out_dir;

    // "dayXX"
    const day_dir = try std.fmt.allocPrint(alloc, "lib/day{s}", .{day_str});
    defer alloc.free(day_dir);

    // Full absolute path: <project_root>/src/dayXX/<filename>
    const input_path = try std.fs.path.join(alloc, &.{ project_root, "src", day_dir, filename });
    defer alloc.free(input_path);

    std.debug.print("input_path: {s}\n", .{input_path});

    const input_file = try std.fs.openFileAbsolute(input_path, .{});
    defer input_file.close();

    const input = try input_file.readToEndAlloc(alloc, 1024 * 1024);
    defer alloc.free(input);

    switch (part) {
        1 => try Day.part1(alloc, input),
        2 => try Day.part2(alloc, input),
        else => {
            try stdout.print("Unknown part {d}, expected 1 or 2\n", .{part});
            return error.UnknownPart;
        },
    }
}
