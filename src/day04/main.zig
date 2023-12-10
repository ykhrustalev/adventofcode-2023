const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

const Game = struct {
    const Self = @This();
    id: u32,
    expected: std.AutoHashMap(u32, void),
    matches: u32,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{ .id = 0, .expected = std.AutoHashMap(u32, void).init(allocator), .matches = 0 };
    }

    pub fn deinit(self: *Self) void {
        self.*.expected.deinit();
    }

    pub fn add(self: *Self, v: u32) !void {
        try self.expected.put(v, void{});
    }

    pub fn check_match(self: *Self, v: u32) void {
        if (self.*.expected.contains(v)) {
            self.*.matches += 1;
        }
    }
};

fn parseInt(v: []const u8) !u32 {
    return try std.fmt.parseInt(u32, std.mem.trimLeft(u8, v, " "), 10);
}

fn parseLine(allocator: std.mem.Allocator, games: *std.ArrayList(Game), line: []const u8) !void {
    var it1 = std.mem.split(u8, line, " | ");
    var rawexpected = it1.first();
    var rawnumbers = it1.rest();

    var game: Game = Game.init(allocator);

    var it2 = std.mem.split(u8, rawexpected, ": ");
    var header = it2.next();
    var it2a = std.mem.split(u8, header.?, " ");
    _ = it2a.next();
    game.id = try parseInt(it2a.rest());

    var it3 = std.mem.split(u8, it2.rest(), " ");
    while (it3.next()) |v| {
        if (v.len > 0) {
            try game.add(try parseInt(v));
        }
    }

    var it4 = std.mem.split(u8, rawnumbers, " ");
    while (it4.next()) |v| {
        if (v.len > 0) {
            game.check_match(try parseInt(v));
        }
    }

    try games.*.append(game);
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var games = std.ArrayList(Game).init(arena.allocator());

    var split = std.mem.split(u8, input, "\n");
    while (split.next()) |line| {
        if (line.len > 0) {
            try parseLine(arena.allocator(), &games, line);
        }
    }

    var cnt: u32 = 0;
    for (games.items) |game| {
        cnt += if (game.matches > 0) std.math.pow(u32, 2, game.matches - 1) else 0;
    }

    return cnt;
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var games = std.ArrayList(Game).init(arena.allocator());

    var split = std.mem.split(u8, input, "\n");
    while (split.next()) |line| {
        if (line.len > 0) {
            try parseLine(arena.allocator(), &games, line);
        }
    }

    var cnt: u32 = 0;

    var slice = try games.toOwnedSlice();

    var queue = std.ArrayList(Game).init(arena.allocator());
    for (slice) |g| {
        try queue.append(g);
    }

    while (queue.items.len > 0) {
        var game = queue.pop();

        cnt += 1;
        if (game.matches == 0) {
            continue;
        }

        for (1..1 + game.matches) |i| {
            try queue.append(slice[game.id + i - 1]);
        }
    }

    return cnt;
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u32, 13), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u32, 21959), r);
}

test "solution2 sample" {
    var r = try solve2(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u32, 30), r);
}

test "solution2 " {
    var r = try solve2(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u32, 5132675), r);
}
