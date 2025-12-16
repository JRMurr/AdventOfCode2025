const std = @import("std");
const BitSet = std.bit_set.DynamicBitSetUnmanaged;
const Direction = std.bit_set.IteratorOptions.Direction;

const aocLib = @import("aocLib");

pub const day = aocLib.Day{ .part1 = part01, .part2 = part02 };

const DigitWorkspace = struct {
    pub const digits: []const u8 = "987654321";
    out: [digits.len]BitSet,

    pub fn init() DigitWorkspace {
        var self = DigitWorkspace{ .out = undefined };
        for (&self.out) |*bs| bs.* = .{};
        return self;
    }

    pub fn deinit(self: *DigitWorkspace, alloc: std.mem.Allocator) void {
        for (&self.out) |*bs| bs.deinit(alloc);
    }
};

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

fn findJoltsP1(comptime digits: []const u8, alloc: std.mem.Allocator, line: []const u8, out: *[digits.len]BitSet) !usize {
    try findPerNeedle(32, digits, alloc, line, out);

    var jolts: usize = 0;

    var tensPlaceFound: bool = false;

    var cutOff: usize = 0;

    // could probably be smart with other conditions but this will make me think less
    var haveAdded = false;

    var num: usize = 9;

    while (num > 1) {
        const digitIdx = 9 - num;
        var matches = &out.*[digitIdx];
        dropBefore(matches, cutOff);
        if (matches.findFirstSet()) |idx| {
            matches.unset(idx);
            defer haveAdded = true;
            const isLastDigit = idx == line.len - 1;

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
        } else {
            num -= 1;
        }
    }

    return jolts;
}

pub fn part01(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    var digits_ws = DigitWorkspace.init();
    defer digits_ws.deinit(alloc);

    var res: usize = 0;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const jolts = try findJoltsP1(
            DigitWorkspace.digits,
            alloc,
            token,
            &digits_ws.out,
        );

        res += jolts;
    }

    std.debug.print("Part 1: {d}\n", .{res});
}

test "findJoltsP1 sample lines" {
    const alloc = std.testing.allocator;
    var ws = DigitWorkspace.init();
    defer ws.deinit(alloc);

    const cases = [_]struct { line: []const u8, expect: usize }{
        .{ .line = "987654321111111", .expect = 98 },
        .{ .line = "811111111111119", .expect = 89 },
        .{ .line = "234234234234278", .expect = 78 },
        .{ .line = "818181911112111", .expect = 92 },
        .{ .line = "1119911", .expect = 99 },
    };

    for (cases) |case| {
        const res = try findJoltsP1(DigitWorkspace.digits, alloc, case.line, &ws.out);
        try std.testing.expectEqual(case.expect, res);
    }
}

pub fn part02(alloc: std.mem.Allocator, input: []const u8) anyerror!void {
    var digits_ws = DigitWorkspace.init();
    defer digits_ws.deinit(alloc);

    var res: usize = 0;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |token| {
        const jolts = try findJoltsP2(
            DigitWorkspace.digits,
            alloc,
            token,
            &digits_ws.out,
        );

        res += jolts;
    }

    std.debug.print("Part 2: {d}\n", .{res});
}

const SelectedNum = struct { idx: usize, num: usize };

fn insertSorted(alloc: std.mem.Allocator, list: *std.ArrayList(SelectedNum), p: SelectedNum) !void {
    const i = std.sort.lowerBound(SelectedNum, list.items, p.idx, comptime struct {
        fn order(context: usize, item: SelectedNum) std.math.Order {
            return std.math.order(context, item.idx);
        }
    }.order);

    try list.insert(alloc, i, p);
}

test "insertSorted keeps list ordered by idx" {
    const alloc = std.testing.allocator;
    var list = std.ArrayList(SelectedNum).empty;
    defer list.deinit(alloc);

    try insertSorted(alloc, &list, .{ .idx = 5, .num = 50 });
    try insertSorted(alloc, &list, .{ .idx = 2, .num = 20 });
    try insertSorted(alloc, &list, .{ .idx = 9, .num = 90 });
    try insertSorted(alloc, &list, .{ .idx = 7, .num = 70 });

    const expected = [_]SelectedNum{
        .{ .idx = 2, .num = 20 },
        .{ .idx = 5, .num = 50 },
        .{ .idx = 7, .num = 70 },
        .{ .idx = 9, .num = 90 },
    };

    try std.testing.expectEqualSlices(SelectedNum, &expected, list.items);
}

const Selected = struct {
    const Self = @This();
    list: std.ArrayList(SelectedNum),
    bs: BitSet,

    fn init(alloc: std.mem.Allocator, bs_len: usize) !Self {
        return .{
            .list = std.ArrayList(SelectedNum).empty,
            .bs = try BitSet.initEmpty(alloc, bs_len),
        };
    }

    fn deinit(self: *Self, alloc: std.mem.Allocator) void {
        self.list.deinit(alloc);
        self.bs.deinit(alloc);
    }

    fn insert(self: *Self, alloc: std.mem.Allocator, p: SelectedNum) !void {
        try insertSorted(alloc, &self.list, p);
        self.bs.set(p.idx);
    }
};

fn countUnsetAfter(bs: BitSet, idx: usize) usize {
    var it = bs.iterator(.{ .kind = .unset, .direction = .forward });
    var n: usize = 0;
    while (it.next()) |i| {
        if (i > idx) {
            n += 1;
        }
    }
    return n;
}

pub fn unionAfter(out: []BitSet, alloc: std.mem.Allocator, idx: usize) !BitSet {
    var result = try BitSet.initEmpty(alloc, out[0].capacity());

    if (idx >= out.len) {
        return result;
    }

    for (idx..(out.len)) |out_idx| {
        const bs = out[out_idx];
        result.setUnion(bs);
    }

    return result;
}

fn firstLastSet(bs: anytype) ?struct { first: usize, last: usize } {
    const first = bs.findFirstSet() orelse return null;
    const last = bs.findLastSet() orelse unreachable; // if first exists, last does too
    return .{ .first = first, .last = last };
}

fn findJoltsP2(comptime digits: []const u8, alloc: std.mem.Allocator, line: []const u8, out: *[digits.len]BitSet) !usize {
    try findPerNeedle(32, digits, alloc, line, out);

    // var jolts: usize = 0;

    var cutOff: usize = 0;

    var num: usize = 9;

    var selected = try Selected.init(alloc, line.len);
    defer selected.deinit(alloc);

    while (num >= 1) {
        std.debug.print("\n----{d}----\n", .{num});
        if (selected.list.items.len >= 12) {
            break;
        }
        const digitIdx = 9 - num;
        var matches = &out.*[digitIdx];

        dropBefore(matches, cutOff);

        // if (matches.findFirstSet()) |idx| {
        //     if (idx < cutOff) break;
        //     const numAvailable = countUnsetAfter(selected.bs, idx);
        //     const currSelected = selected.bs.count();

        //     if (currSelected + numAvailable >= 12) {
        //         cutOff = idx;
        //     }
        // }

        var possibleAfter = try unionAfter(out, alloc, digitIdx + 1);
        defer possibleAfter.deinit(alloc);

        dropBefore(&possibleAfter, cutOff);

        // var it = AnyBitIter.init(matches, if (possibleAfter.count() == 0) .reverse else .forward);

        var it = matches.iterator(.{});

        while (it.next()) |idx| {
            if (selected.list.items.len < 12) {
                try selected.insert(alloc, .{ .idx = idx, .num = num });
            }
        }

        if (num == 1) {
            break;
        }

        // var selectedIt = selected.bs.iterator(.{});
        const currSelected = selected.bs.count();

        if (firstLastSet(selected.bs)) |fs| {
            // TODO: this gets sad when first and last elem are selected.....
            // need to be smarter about cutting off
            std.debug.print("fs: {}\n", .{fs});
            const start = @max(cutOff, fs.first);

            for (start..(fs.last + 1)) |idx| {
                const numAvailable = countUnsetAfter(selected.bs, idx);

                std.debug.print("cutOff: {d}\t currSelected: {d}\tidx: {d}\tnumAvailable: {d}\n", .{
                    cutOff,
                    currSelected,
                    idx,
                    numAvailable,
                });
                if (currSelected + numAvailable >= 12) {
                    cutOff = idx;
                }
            }
        }

        // while (selectedIt.next()) |idx| {
        //     if (idx < cutOff) continue;

        //     const numAvailable = countUnsetAfter(selected.bs, idx);

        //     if (currSelected + numAvailable >= 12) {
        //         cutOff = idx;
        //     }
        // }

        num -= 1;
    }

    var res: usize = 0;
    for (0..12) |idx| {
        const base = selected.list.items[idx].num;
        const raise = 11 - idx;

        res += base * std.math.pow(usize, 10, raise);
    }

    return res;
}

test "findJoltsP2 sample lines" {
    const alloc = std.testing.allocator;
    var ws = DigitWorkspace.init();
    defer ws.deinit(alloc);

    const cases = [_]struct { line: []const u8, expect: usize }{
        // .{ .line = "987654321111111", .expect = 987654321111 },
        // .{ .line = "811111111111119", .expect = 811111111119 },
        // .{ .line = "234234234234278", .expect = 434234234278 },
        // .{ .line = "818181911112111", .expect = 888911112111 },
        // .{ .line = "838383933533333", .expect = 888933533333 },
        // .{ .line = "858383935533333", .expect = 888935533333 },
        // .{ .line = "958383935533339", .expect = 988935533339 },
        // .{ .line = "911511118111119", .expect = 951118111119 },
        .{ .line = "922511118111119", .expect = 951118111119 },
    };

    for (cases) |case| {
        const res = try findJoltsP2(DigitWorkspace.digits, alloc, case.line, &ws.out);
        try std.testing.expectEqual(case.expect, res);
    }
}

test "getNumUnSetAfter counts set bits through idx" {
    const alloc = std.testing.allocator;
    var bs = try BitSet.initEmpty(alloc, 16);
    defer bs.deinit(alloc);

    bs.set(0);
    bs.set(5);
    bs.set(14);

    const count = countUnsetAfter(bs, 9);
    try std.testing.expectEqual(@as(usize, 6), count);
}
