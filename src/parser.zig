const std = @import("std");
const stack = @import("stack.zig");

const Errors = error{Genral};
const JsonType = enum {
    Array,
    Object,
    Hueristic,
    Name,
    String,
    Number,
    Constant,
};
const State = enum {
    Success,
    Failure,
};

const JsonStr = struct {
    chars: []const u8,
    len: usize,

    pub fn init(allocator: std.mem.Allocator, string: []const u8, len: usize) !*JsonStr {
        const new_value = try allocator.create(JsonStr);
        new_value.*.chars = string;
        new_value.*.len = len;
        return new_value;
    }
};

const JsonValueUnion = union {
    string: *JsonStr,
    number: isize,
    object: *JsonObject,
    array: *JsonArray,
    boolean: bool,
    null: i32,
};

const JsonValue = struct {
    parent: ?*JsonValue,
    value_type: JsonType,
    value: JsonValueUnion,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, t: JsonType) !?*JsonValue {
        const new_value = allocator.create(JsonValue) catch |err| {
            return err;
        };
        new_value.*.parent = null;
        new_value.*.value_type = t;
        //var obj = JsonObject.init(allocator) catch |err| {
        //  return err;
        //};
        //new_value.*.value = JsonValueUnion{ .object = obj };
        new_value.*.allocator = allocator;
        return new_value;
    }

    pub fn deinit(self: *JsonValue) void {
        self.allocator.destroy(self.value);
        self.allocator.destroy(self);
    }
};

const JsonObject = struct {
    wrapping_value: *JsonValue,
    cells: []isize,
    hashes: []i64,
    names: [][]const u8,
    values: []*JsonValue,
    cell_idxs: []i64,
    count: i32,
    item_cap: i32,
    cell_cap: i32,
    pub fn init(allocator: std.mem.Allocator) !*JsonObject {
        const new_value = try allocator.create(JsonObject);

        return new_value;
    }
};

const JsonArray = struct {
    wrapping_value: *JsonValue,
    items: []*JsonValue,
    count: i32,
    cap: i32,
};

pub fn hex_char_to_int(ch: u8) i32 {
    if (ch >= '0' and ch <= '9') {
        return ch - '0';
    }
    if (ch >= 'a' and ch <= 'f') {
        return ch - 'a' + 10;
    }
    if (ch >= 'A' and ch <= 'F') {
        return ch - 'A' + 10;
    }
    return -1;
}

pub fn json_parse(src: []const u8) !?*JsonValue {
    var current_index: usize = 0;
    var nesting: usize = 0;
    return parse_value(src, &current_index, nesting);
}

fn parse_object_value(src: []const u8, current_index: *usize, nesting: usize) !?*JsonValue {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const out_value: ?*JsonValue = JsonValue.init(allocator, JsonType.Object) catch |err| {
        return err;
    };
    if (src[current_index.*] != '{') {
        return null;
    }
    const out_object = JsonObject.init(allocator) catch |err| {
        return err;
    };
    _ = out_object;
    // skiping current char
    current_index.* += 1;
    skip_white_space(src, current_index);

    // in case of an empty object
    if (src[current_index.*] == '}') {
        current_index.* += 1;
        return out_value;
    }

    while (src.len > current_index.*) {
        std.debug.print("current index: {any}\n", .{current_index.*});
        var new_key: [255]u8 = undefined;
        const len = get_quoted_string(src, current_index, &new_key) catch |err| {
            return err;
        };
        if (src[current_index.*] == '\"') {
            current_index.* += 1;
        }
        std.debug.print("current_index after key: {any} = {c}\n", .{ current_index.*, src[current_index.*] });
        std.debug.print("new key: {s}\n", .{new_key[1 .. len + 1]});

        if (src[current_index.*] != ':') {
            // TODO: need to hadnle this later by freeing memory up
        }
        current_index.* += 1;
        const new_value = parse_value(src, current_index, nesting + 1) catch |err| {
            return err;
        };
        _ = new_value;

        var obj = try JsonObject.init(allocator);
        .std.debug.print("new value: {any}\n", .{obj});
    }
    return out_value;
}

pub fn parse_string_value(src: []const u8, current_index: *usize) !?*JsonValue {
    var new_value: [255]u8 = undefined;
    const len = try get_quoted_string(src, current_index, &new_value);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var value = try JsonValue.init(allocator, JsonType.String);
    value.?.*.value = JsonValueUnion{ .string = try JsonStr.init(allocator, &new_value, len) };
    return value;
}

pub fn parse_value(src: []const u8, current_index: *usize, nesting: usize) !?*JsonValue {
    switch (src[current_index.*]) {
        '{' => {
            return parse_object_value(src, current_index, nesting + 1);
        },
        '\"' => {
            return parse_string_value(src, current_index);
        },
        else => {
            return Errors.Genral;
        },
    }
}
fn skip_white_space(src: []const u8, current_index: *usize) void {
    while (std.ascii.isWhitespace(src[current_index.*])) {
        current_index.* += 1;
    }
}

// TODO: create error types;
fn skip_quotes(src: []const u8, current_index: *usize) usize {
    std.debug.print("src: {s}\ncurrent: {c}\nidx: {}\n", .{ src, src[current_index.*], current_index.* });
    if (src[current_index.*] != '\"') {
        return 0;
    }
    current_index.* += 1;
    var len: usize = 0;
    if (current_index.* == src.len) {
        return 0;
    }
    while (src[current_index.*] != '\"') {
        if (src.len == current_index.*) {
            return 0;
        } else if (src[current_index.*] == '\\') {
            current_index.* += 1;
            if (src.len == current_index.*) {
                return 0;
            }
        }
        current_index.* += 1;
        len += 1;
    }
    return len;
}

fn process_string(src: []const u8, start: *usize, out_char: []u8) !void {
    var index: usize = 0;
    while (src.len > start.*) {
        if (src[start.*] == '\\') {
            start.* += 1;
            switch (src[start.*]) {
                '\"' => {
                    out_char[index] = '\"';
                },
                '\\' => {
                    out_char[index] = '\\';
                },
                '/' => {
                    out_char[index] = '/';
                },
                'n' => {
                    out_char[index] = '\n';
                },
                'r' => {
                    out_char[index] = '\r';
                },
                't' => {
                    out_char[index] = '\t';
                },
                else => {
                    // TODO: Actually handle this case
                    std.debug.print("case: {c}", .{src[start.*]});
                },
            }
        } else {
            out_char[index] = src[start.*];
        }
        index += 1;
        start.* += 1;
    }
}

fn get_quoted_string(src: []const u8, current_index: *usize, out_char: []u8) !usize {
    var str_start: usize = current_index.*;
    var input_str_len = skip_quotes(src, current_index);
    // TODO: handle no len strings;
    // if (input_str_len == 0) {
    //   return ;
    // }
    try process_string(src, &str_start, out_char);
    return input_str_len;
}
