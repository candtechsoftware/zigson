const std = @import("std");

pub fn read_file(filename: []const u8) ![]const u8 {
    const data = try std.fs.cwd().openFile(filename, .{});
    defer data.close();
    const allocator = std.heap.page_allocator;
    const file_size = (try data.stat()).size;
    const file_buffer = try allocator.alloc(u8, file_size);
    const n = try data.readAll(file_buffer);
    _ = n;
    return file_buffer;
}
