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

    // Adjust this path to your layout (here: src/dayXX/in or in.example)
    const input_path = try std.fmt.allocPrint(alloc, "src/day{s}/{s}", .{ day_str, filename });
    defer alloc.free(input_path);

    const cwd = std.fs.cwd();
    const input = try cwd.readFileAlloc(alloc, input_path, 1024 * 1024);
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