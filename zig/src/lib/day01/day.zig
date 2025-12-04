const std = @import("std");

const aocLib = @import("../root.zig");

pub const day = aocLib.Day{ .part1 = part01, .part2 = part02 };

const Dir = enum { Left, Right };

pub fn part01(_: std.mem.Allocator, input: []const u8) anyerror!void {
    var pos: i32 = 50;

    var num_zero: u32 = 0;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const dir = if (token[0] == 'L') Dir.Left else Dir.Right;
        const num = try std.fmt.parseInt(u32, token[1..], 10);

        // if they have a big number specified we can just mod 100 to normalize the spin
        const spin_normalized: i32 = @intCast(num % 100);

        const spin_with_dir: i32 = if (dir == Dir.Left) (spin_normalized * -1) else spin_normalized;

        const new_pos = pos + spin_with_dir;

        pos = if (new_pos < 0) (100 + new_pos) else (@mod(new_pos, 100));

        if (pos == 0) {
            num_zero += 1;
        }
        // std.debug.print("dir: {}\t num: {d} \t spin_normalized: {d} \t spin_with_dir: {d} \t \t new_pos: {d} pos: {d}\n", .{ dir, num, spin_normalized, spin_with_dir, new_pos, pos });
    }

    std.debug.print("Part 1\nnum_zero: {d}\n", .{num_zero});
}

pub fn part02(_: std.mem.Allocator, input: []const u8) anyerror!void {
    var pos: i32 = 50;

    var num_zero: u32 = 0;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const dir = if (token[0] == 'L') Dir.Left else Dir.Right;
        const num = try std.fmt.parseInt(u32, token[1..], 10);

        // if they have a big number specified we can just mod 100 to normalize the spin
        // but see how many times we did spin
        const num_full_spins = try std.math.divFloor(u32, num, 100);

        num_zero += num_full_spins;

        const spin_normalized: i32 = @intCast(num % 100);

        const spin_with_dir: i32 = if (dir == Dir.Left) (spin_normalized * -1) else spin_normalized;

        const new_pos = pos + spin_with_dir;

        if (new_pos < 0) {
            pos = (100 + new_pos);
            num_zero += 1;

            if (pos == 0) {
                num_zero += 1;
            }
        } else if (new_pos == 0) {
            num_zero += 1;
        } else {
            pos = @mod(new_pos, 100);
            num_zero += try std.math.divFloor(u32, @intCast(new_pos), 100);
        }

        std.debug.print("dir: {}\t num: {d} \t num_full_spins: {d} \t spin_normalized: {d} \t spin_with_dir: {d} \t new_pos: {d} pos: {d}\n", .{
            dir,
            num,
            num_full_spins,
            spin_normalized,
            spin_with_dir,
            new_pos,
            pos,
        });
    }

    std.debug.print("Part 2\nnum_zero: {d}\n", .{num_zero});
}
