const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

fn find_dist(total_time: u64, wait_time: u64) u64 {
    const v = wait_time;
    return v * (total_time - wait_time);
}

const Game = struct {
    time: u64,
    distance: u64,

    pub fn soulutions_cnt(self: *const Game) u64 {
        var r: u64 = 0;

        var wait_time = self.*.time;
        while (true) {
            var d = find_dist(self.*.time, wait_time);
            if (d > self.*.distance) {
                r += 1;
            }
            if (wait_time > 0) {
                wait_time -= 1;
            } else {
                break;
            }
        }

        return r;
    }
};

fn parseValues(alloc: std.mem.Allocator, line: []const u8) ![]u64 {
    var it = std.mem.split(u8, line, ": ");
    _ = it.next();

    var arr = std.ArrayList(u64).init(alloc);
    defer arr.deinit();

    var it2 = std.mem.split(u8, it.rest(), " ");
    while (it2.next()) |v| {
        if (v.len > 0) {
            try arr.append(try std.fmt.parseInt(u64, v, 10));
        }
    }

    return try arr.toOwnedSlice();
}

fn parseInput(alloc: std.mem.Allocator, input: []const u8) ![]Game {
    var r = std.ArrayList(Game).init(alloc);

    var it = std.mem.split(u8, input, "\n");

    var times_slice = try parseValues(alloc, it.next().?);
    var dist_slice = try parseValues(alloc, it.next().?);

    for (times_slice, dist_slice) |t, d| {
        try r.append(Game{ .time = t, .distance = d });
    }

    return try r.toOwnedSlice();
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var games = try parseInput(arena.allocator(), input);

    var r: u64 = 1;

    for (games) |g| {
        r *= g.soulutions_cnt();
    }

    return r;
}

fn parseValue2(alloc: std.mem.Allocator, line: []const u8) !u64 {
    var it = std.mem.split(u8, line, ": ");
    _ = it.next();

    var tmp = std.ArrayList(u8).init(alloc);
    defer tmp.deinit();

    var rest = it.rest();
    for (rest) |c| {
        if (std.ascii.isDigit(c)) {
            try tmp.append(c);
        }
    }

    return try std.fmt.parseInt(u64, try tmp.toOwnedSlice(), 10);
}

fn parseInput2(alloc: std.mem.Allocator, input: []const u8) !Game {
    var it = std.mem.split(u8, input, "\n");

    var time = try parseValue2(alloc, it.next().?);
    var dist = try parseValue2(alloc, it.next().?);

    var g = Game{ .time = time, .distance = dist };

    return g;
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var game = try parseInput2(arena.allocator(), input);
    return game.soulutions_cnt();
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u64, 288), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u64, 138915), r);
}

test "solution2 sample" {
    var r = try solve2(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u64, 71503), r);
}

test "solution2 " {
    var r = try solve2(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u64, 27340847), r);
}
