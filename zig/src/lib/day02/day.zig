const std = @import("std");

const mecha = @import("mecha");

const aocLib = @import("../root.zig");

pub const day = aocLib.Day{ .part1 = part01, .part2 = part02 };

const Range = struct { start: u64, end: u64 };

const intParse = mecha.int(u64, .{ .parse_sign = false });

const rangeParse = mecha.combine(.{
    intParse,
    mecha.utf8.char('-').discard(),
    intParse,
}).map(mecha.toStruct(Range));

fn stripNewLine(alloc: std.mem.Allocator, input: []const u8) ![]const u8 {
    const size = std.mem.replacementSize(u8, input, "\n", "");

    const out = try alloc.alloc(u8, size);

    const replaced = std.mem.replace(u8, input, "\n", "", out);

    std.debug.assert(replaced > 0);

    return out;
}

pub fn part01(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const stripped = try stripNewLine(alloc, input);
    defer alloc.free(stripped);

    var res: u64 = 0;

    var it = std.mem.tokenizeScalar(u8, stripped, ',');
    while (it.next()) |token| {
        const range = (try rangeParse.parse(alloc, token)).value.ok;

        for ((range.start)..(range.end + 1)) |x| {
            const numDigits = std.math.log10_int(x) + 1;
            if (numDigits % 2 != 0) {
                continue;
            }

            const toRaise = try std.math.divFloor(u64, numDigits, 2);

            const div = std.math.pow(u64, 10, toRaise);

            const first = try std.math.divFloor(u64, x, div);

            const second = x - (first * div);

            // std.debug.print("x: {d}\tdiv: {d}\tnumDigits: {}\t\tfirst: {d}\tsecond: {}\n", .{ x, div, numDigits, first, second });

            if (first == second) {
                res += x;
                // std.debug.print("{d}\n", .{x});
            }
        }

        // std.debug.print("tok: {s}\trange:{}\n", .{ token, range });
    }
    std.debug.print("Part 1: {d}\n", .{res});
}

pub fn part02(_: std.mem.Allocator, _: []const u8) anyerror!void {
    std.debug.print("Part 2\n", .{});
}
