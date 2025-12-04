const std = @import("std");

const gen = @import("days_generated");
pub const days = gen.days;

const aocLib = @import("root.zig");

// const days = .{
//     .{ "01", @import("day01/day.zig").day },
//     .{ "02", @import("day02/day.zig").day },
// };

// pub const days = blk: {
//     var arr: [2]struct { []const u8, aocLib.Day } = undefined;

//     for (std.meta.intRange(u8, 1, 3), 0..) |n, i| {
//         const mod = @import(std.fmt.comptimePrint("day{d:0>2}/day.zig", .{n}));
//         arr[i] = .{
//             std.fmt.comptimePrint("{d:0>2}", .{n}),
//             mod.day,
//         };
//     }

//     break :blk arr;
// };

pub const dayMap = std.static_string_map.StaticStringMap(aocLib.Day).initComptime(days);
