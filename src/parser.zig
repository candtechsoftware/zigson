const std = @import("std");
const stack = @import("stack.zig");

const ParserError = error{
    Genral,
    OutOfBounds,
    Invalid,
};

const JsonType = enum {
    False,
    True,
    Null,
    Number,
    String,
    Array,
    Object,
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

    pub fn can_access_index(self: *Buffer, index: usize) bool {
        return (self.*.offset + index) > self.*.buffer_len;
    }

    pub fn current(self: *Buffer) !u8 {
        if (self.*.contents.len >= self.*.offset) {
            return ParserError.OutOfBounds;
        }
        return self.*.Buffer[self.*.offset];
    }

    pub fn check_keyword(self: *Buffer) ?JsonType {
        if (std.mem.eql(u8, self.*.buffer[self.*.buffer.offset..5], "true")) {
            return JsonType.True;
        }
        if (std.mem.eql(u8, self.*.buffer[self.*.buffer.offset..6], "false")) {
            return JsonType.True;
        }
        if (std.mem.eql(u8, self.*.buffer[self.*.buffer.offset..5], "null")) {
            return JsonType.Null;
        }
        if (self.*.buffer[self.*.offset] == '-' or (self.*.buffer[self.*.offset] >= 0 and self.*.buffer[self.*.offset] <= '0')) {
            return JsonType.Number;
        }
        return null;
    }

    pub fn skip_whitespace(self: *Buffer) void {
        if (self.*.contents.len == 0) {
            return;
        }

        if (self.can_access_index(0)) {
            return;
        }

        while (self.can_access_index(0) and (self.buffer_at_offset() <= 32)) {
            self.*.offset += 1;
        }

        if (self.*.offest == self.*.buffer_len) {
            self.*.offset -= 1;
        }
    }
};

pub fn parser(allocator: std.mem.Allocator) type {
    return struct {
        pub const arena = allocator;
        pub fn parse_with_len_options(value: []const u8, buffer_len: usize, parse_end: usize) *JValue {
            _ = parse_end;
            var buffer = Buffer.init(arena);
            buffer.?.*.contents = value;
            buffer.?.*.len = buffer_len;
            buffer.?.*.offset = 0;

            var item = JValue.init(arena);
            _ = item;
        }

        pub fn parse_value(item: *JValue, buffer: Buffer) !void {
            switch (buffer.current()) {
                '{' => {
                    // TODO: Parse object
                },
                '[' => {
                    // TODO: Parse array
                },
                '\"' => {
                    // TODO: Parse string
                },
                else => {
                    // TODO: check if number | bool
                    const t = buffer.check_keyword();
                    item.*.value_type = t;
                    switch (t) {
                        .Number => {
                            //TODO parser number,
                        },
                        .Null, .True => {
                            buffer.offset += 4;
                        },
                        .False => {
                            buffer.offset += 5;
                        },

                        else => {
                            return ParserError.Invalid;
                        },
                    }
                    // then parse accordingly
                },
            }
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
