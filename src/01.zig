const std = @import("std");
const testing = std.testing;

pub fn solve1(input: []const u8) !u32 {
    var splits = std.mem.split(u8, input, "\n");

    var r: u32 = 0;
    while (splits.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        var left: ?usize = null;
        var right: ?usize = null;

        for (line, 0..) |c, i| {
            if (std.ascii.isDigit(c)) {
                left = i;
                break;
            }
        }

        var i = line.len;
        while (i > 0) {
            i -= 1;

            const c = line[i];
            if (std.ascii.isDigit(c)) {
                right = i;
                break;
            }
        }

        if ((left == null) or (right == null)) {
            continue;
        }

        var num = [_]u8{ line[left.?], line[right.?] };
        var parsed = try std.fmt.parseInt(u32, &num, 10);
        r += parsed;
    }

    return r;
}

///
var digits = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
var digits_r = [_][]const u8{ "eno", "owt", "eerht", "ruof", "evif", "xis", "neves", "thgie", "enin" };

fn gen_map(allocator: std.mem.Allocator, names: [][]const u8) !std.StringHashMap(u32) {
    var m = std.StringHashMap(u32).init(allocator);
    for (names, 1..) |k, v| {
        try m.put(k, @intCast(v));
    }
    return m;
}

const NumError = error{ NotFound, OutOfMemory };

fn find_left(line: []const u8, m: std.StringHashMap(u32)) NumError!u32 {
    var pos: ?usize = null;
    var value: ?u32 = null;

    var it = m.iterator();
    while (it.next()) |item| {
        var p = std.mem.indexOf(u8, line, item.key_ptr.*);
        if (p != null) {
            if (pos == null or p.? < pos.?) {
                pos = p.?;
                value = item.value_ptr.*;
            }
        }
    }

    for (line, 0..) |c, i| {
        if (std.ascii.isDigit(c)) {
            if (pos == null or i < pos.?) {
                if (std.fmt.charToDigit(c, 10)) |conveted| {
                    value = @intCast(conveted);
                } else |_| {
                    unreachable;
                }
            }
            break;
        }
    }

    if (value) |v| {
        return v;
    }
    return NumError.NotFound;
}

fn find_right(allocator: std.mem.Allocator, line: []const u8, m: std.StringHashMap(u32)) NumError!u32 {
    var buf = try allocator.alloc(u8, line.len);
    defer allocator.free(buf);
    std.mem.copy(u8, buf, line);
    std.mem.reverse(u8, buf);

    return try find_left(buf, m);
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var m = try gen_map(allocator, &digits);
    defer m.deinit();

    var mr = try gen_map(allocator, &digits_r);
    defer mr.deinit();

    var splits = std.mem.split(u8, input, "\n");

    var r: u32 = 0;
    while (splits.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (find_left(line, m)) |left| {
            if (find_right(allocator, line, mr)) |right| {
                r += 10 * left + right;
            } else |_| {}
        } else |_| {}
    }

    return r;
}

test "solution1" {
    var r = try solve1(@embedFile("input/01.input"));
    try testing.expectEqual(@as(u32, 54159), r);
}

test "solution2" {
    var r = try solve2(testing.allocator, @embedFile("input/01.input"));
    try testing.expectEqual(@as(u32, 53866), r);
}

test "left" {
    var m = try gen_map(testing.allocator, &digits);
    defer m.deinit();

    try testing.expect(1 == try find_left("one", m));
    try testing.expect(2 == try find_left("2", m));
    try testing.expect(3 == try find_left("xxxthree", m));
    try testing.expect(4 == try find_left("xxx4three", m));
    try testing.expectError(NumError.NotFound, find_left("xxx", m));
}

test "right" {
    var m = try gen_map(testing.allocator, &digits_r);
    defer m.deinit();

    try testing.expect(1 == try find_right(testing.allocator, "one", m));
    try testing.expect(2 == try find_right(testing.allocator, "2", m));
    try testing.expect(3 == try find_right(testing.allocator, "threexxx", m));
    try testing.expect(4 == try find_right(testing.allocator, "three4xxx", m));
    try testing.expectError(NumError.NotFound, find_right(testing.allocator, "xxx", m));
}
