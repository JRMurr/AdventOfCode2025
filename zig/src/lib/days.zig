const std = @import("std");
const aocLib = @import("root.zig");


const day01 = @import("day01/day.zig");

pub const dayMap = std.static_string_map.StaticStringMap(aocLib.Day).initComptime(.{
    .{"01", day01.day}
});
