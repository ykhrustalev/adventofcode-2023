const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

const Input = struct {
    const Line = struct {
        const Self = @This();

        values: []i32,

        pub fn parse(alloc: std.mem.Allocator, line: []const u8) !Self {
            var arr = std.ArrayList(i32).init(alloc);
            defer arr.deinit();

            var it = std.mem.split(u8, line, " ");
            while (it.next()) |v| {
                try arr.append(try std.fmt.parseInt(i32, v, 10));
            }

            return Line{ .values = try arr.toOwnedSlice() };
        }
    };

    lines: []Line,

    pub fn parse(alloc: std.mem.Allocator, input: []const u8) !Input {
        var it = std.mem.split(u8, input, "\n");

        var arr = std.ArrayList(Line).init(alloc);
        defer arr.deinit();

        while (it.next()) |line| {
            if (line.len > 0) {
                try arr.append(try Line.parse(alloc, line));
            }
        }

        return Input{ .lines = try arr.toOwnedSlice() };
    }
};

fn has_non_zero(arr: []const i32) bool {
    for (arr) |v| {
        if (v != 0) {
            return true;
        }
    }
    return false;
}

fn get_diff(a: i32, b: i32) i32 {
    // return if (a < b) b - a else a - b;
    return b - a;
}

fn get_ext(alloc: std.mem.Allocator, orig: []i32) !i32 {
    var arr = try alloc.alloc(i32, orig.len);
    defer alloc.free(arr);

    std.mem.copy(i32, arr, orig);

    var cur_len = arr.len;
    // std.debug.print("{any}\n", .{arr});

    while (true) {
        cur_len -= 1;
        for (1..cur_len + 1) |i| {
            arr[i - 1] = get_diff(arr[i - 1], arr[i]);
        }
        // std.debug.print(" {any}\n", .{arr[0..cur_len]});
        if (!has_non_zero(arr[0..cur_len])) {
            break;
        }
    }

    var v: i32 = 0;
    while (cur_len < orig.len) : (cur_len += 1) {
        v = arr[cur_len] + v;
        // std.debug.print(" {any}\n", .{v});
    }

    return v;
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !i32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try Input.parse(arena.allocator(), input);

    var r: i32 = 0;
    for (inputs.lines) |line| {
        r += try get_ext(arena.allocator(), line.values);
    }

    return r;
}

fn get_prev(alloc: std.mem.Allocator, orig: []i32) !i32 {
    var arr = try alloc.alloc(i32, orig.len + 1);
    defer alloc.free(arr);

    std.mem.copy(i32, arr, orig);

    var cur_len = orig.len;
    std.debug.print("{any}\n", .{arr});
    arr[cur_len] = arr[0];

    while (true) {
        cur_len -= 1;
        for (1..cur_len + 1) |i| {
            arr[i - 1] = get_diff(arr[i - 1], arr[i]);
        }
        arr[cur_len] = arr[0];
        std.debug.print(" {any} - {}\n", .{ arr[0..cur_len], arr[cur_len] });
        if (!has_non_zero(arr[0..cur_len])) {
            break;
        }
    }

    var v: i32 = 0;
    while (cur_len <= orig.len) : (cur_len += 1) {
        v = arr[cur_len] - v;
        std.debug.print(" {any}\n", .{v});
    }

    return v;
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !i32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try Input.parse(arena.allocator(), input);

    var r: i32 = 0;
    for (inputs.lines) |line| {
        r += try get_prev(arena.allocator(), line.values);
    }

    return r;
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input-00"));
    try testing.expectEqual(@as(i32, 114), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(i32, 19637), r);
}

test "solution2 sample" {
    var r = try solve2(testing.allocator, @embedFile("input-00b"));
    try testing.expectEqual(@as(i32, 5), r);
}

test "solution2" {
    var r = try solve2(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(i32, 33), r);
}
