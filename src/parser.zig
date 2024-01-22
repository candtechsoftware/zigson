const std = @import("std");
const stack = @import("stack.zig");

const ParserError = error{Genral};

const JsonType = enum {
    Array,
    Object,
    Hueristic,
    Name,
    String,
    Number,
    Constant,
};

const JValue = struct {
    next: ?*JValue,
    prev: ?*JValue,
    child: ?*JValue,
    value_type: JsonType,
    value_str: []const u8,
    value_int: i64,
    value_double: i128,
    value_string: []const u8,

    pub fn init(allocator: std.mem.Allocator) ?*JValue {
        const mem = allocator.create(JValue) catch {
            return null;
        };
        return mem;
    }
};

const Buffer = struct {
    contents: []const u8,
    len: usize,
    offset: usize,
    depth: usize,

    pub fn init(allocator: std.mem.Allocator) ?*JValue {
        const mem = allocator.create(Buffer) catch {
            return null;
        };
        return mem;
    }
};

pub fn parser(allocator: std.mem.Allocator) type {
    return struct {
        pub const arena = allocator;
        pub fn parse_with_len_options(value: []const u8, buffer_len: usize, parse_end: usize) *JValue {
            _ = parse_end;
            _ = value;
            var buffer = Buffer.init(arena);
            buffer.?.*.contents = "";
            buffer.?.*.len = buffer_len;
            buffer.?.*.offset = 0;

            var item = JValue.init(arena);
            _ = item;
        }
        pub fn parser_with_options(value: []const u8, parse_end: usize) *JValue {
            const buffer_len = value.len;

            return parse_with_len_options(value, buffer_len, parse_end);
        }

        pub fn parse(value: []const u8) *JValue {
            return parser_with_options(value, 0);
        }
    };
}
