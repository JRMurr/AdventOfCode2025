const std = @import("std");
const BitSet = std.bit_set.DynamicBitSetUnmanaged;

const aocLib = @import("aocLib");

pub const day = aocLib.Day{ .part1 = part01, .part2 = part02 };

fn MaskInt(comptime LANES: usize) type {
    return std.meta.Int(.unsigned, LANES); // u16/u32/u64
}

pub fn findPerNeedle(
    comptime LANES: usize,
    comptime needles: []const u8,
    alloc: std.mem.Allocator,
    s: []const u8,
    out: *[needles.len]BitSet,
) !void {
    const Vec = @Vector(LANES, u8);
    const M = MaskInt(LANES);

    // Ensure each bitset is the right length and cleared.
    inline for (out.*, 0..) |_, k| {
        var bs = &out.*[k];
        try bs.resize(alloc, s.len, false);
        bs.setRangeValue(.{ .start = 0, .end = s.len }, false);
    }

    comptime var needleVecs: [needles.len]Vec = undefined;
    inline for (needles, 0..) |needle, k| {
        needleVecs[k] = @as(Vec, @splat(needle));
    }

    var i: usize = 0;
    while (i + LANES <= s.len) : (i += LANES) {
        const v: Vec = std.mem.bytesAsValue([LANES]u8, s[i .. i + LANES]).*;

        inline for (needleVecs, 0..) |nv, k| {
            var m: M = @bitCast(v == nv);
            while (m != 0) {
                const bit: usize = @intCast(@ctz(m));
                out[k].set(i + bit);
                m &= m - 1;
            }
        }
    }

    while (i < s.len) : (i += 1) {
        inline for (needles, 0..) |needle, k| {
            if (s[i] == needle) out[k].set(i);
        }
    }
}

pub fn dropBefore(bs: *BitSet, cutoff: usize) void {
    if (cutoff == 0) {
        return;
    }
    const end = @min(cutoff, bs.bit_length);
    bs.setRangeValue(.{ .start = 0, .end = end }, false);
}

fn findJolts(comptime digits: []const u8, alloc: std.mem.Allocator, line: []const u8, out: *[digits.len]BitSet) !usize {
    try findPerNeedle(32, digits, alloc, line, out);

    var jolts: usize = 0;

    var tensPlaceFound: bool = false;

    var cutOff: usize = 0;

    // could probably be smart with other conditions but this will make me think less
    var haveAdded = false;

    for (out.*, 0..) |_, digitIdx| {
        var matches = &out.*[digitIdx];
        const num = 9 - digitIdx;
        dropBefore(matches, cutOff);
        if (matches.findFirstSet()) |idx| {
            defer haveAdded = true;
            const isLastDigit = idx != line.len - 1;

            if (!isLastDigit) {
                cutOff = idx;
            }

            if (!isLastDigit and !tensPlaceFound) {
                tensPlaceFound = true;
                jolts += num * 10;
            } else {
                jolts += num;
            }

            if (haveAdded) {
                return jolts;
            }
        }
    }

    return jolts;
}

pub fn part01(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    const digits: []const u8 = "98765432";

    var out: [digits.len]BitSet = undefined;

    for (&out) |*bs| bs.* = .{};
    defer for (&out) |*bs| bs.deinit(alloc);

    var res: usize = 0;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const jolts = try findJolts(
            digits,
            alloc,
            token,
            &out,
        );

        res += jolts;
    }

    std.debug.print("Part 1: {d}\n", .{res});
}

pub fn part02(_: std.mem.Allocator, _: []const u8) anyerror!void {
    std.debug.print("Part 2\n", .{});
}

test {
    std.testing.refAllDecls(@This());
}
