const std = @import("std");

const aocLib = @import("../root.zig");

pub const day = aocLib.Day{ .part1 = part01, .part2 = part02 };

const Dir = enum { Left, Right };

pub fn part01(_: std.mem.Allocator, _: []const u8) anyerror!void {
    std.debug.print("Part 1\n", .{});
}

pub fn part02(_: std.mem.Allocator, _: []const u8) anyerror!void {
    std.debug.print("Part 2\n", .{});
}
