const std = @import("std");

const aocLib = @import("../root.zig");

pub const day = aocLib.Day{ .part1 = part01, .part2 = part02 };

const Dir = enum { Left, Right };

fn stripNewLine(alloc: std.mem.Allocator, input: []const u8) ![]const u8 {
    const size = std.mem.replacementSize(u8, input, "\n", "");

    const out = try alloc.alloc(u8, size);

    std.mem.replace(u8, input, "\n", "", out);

    return out;
}

pub fn part01(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const stripped = try stripNewLine(alloc, input);
    defer alloc.free(stripped);

    var it = std.mem.tokenizeScalar(u8, stripped, ',');
    while (it.next()) |token| {}
    std.debug.print("Part 1\n", .{});
}

pub fn part02(_: std.mem.Allocator, _: []const u8) anyerror!void {
    std.debug.print("Part 2\n", .{});
}
