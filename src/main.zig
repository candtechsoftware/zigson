const std = @import("std");
const reader = @import("reader.zig");
const parser = @import("parser.zig");

pub fn main() !void {
    const contents = try reader.read_file("test.json");
    const allocator = std.heap.ArenaAllocator(std.heap.page_allocator);
    const value = parser.parser(allocator).parse(contents);
    std.debug.print("{any}", .{value});
}
