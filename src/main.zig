const std = @import("std");
const reader = @import("reader.zig");
const parser = @import("parser.zig");

pub fn main() !void {
    const contents = try reader.read_file("test.json");
    const r = parser.json_parse(contents);
    std.debug.print("{any}", .{r});
}
