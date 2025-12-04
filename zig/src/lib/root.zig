//! By convention, root.zig is the root source file when making a library.
const std = @import("std");


pub const SolverFn = *const fn (std.mem.Allocator, []const u8) anyerror!void;

pub const Day = struct {
    part1: SolverFn,
    part2: SolverFn,
};

pub const Days = @import("days.zig");

