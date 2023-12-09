const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

const Play = struct {
    red: u32,
    green: u32,
    blue: u32,

    pub fn create() Play {
        return Play{ .red = 0, .green = 0, .blue = 0 };
    }

    pub fn set(self: *Play, key: []const u8, v: u32) void {
        if (std.mem.eql(u8, key, "red")) {
            self.red = v;
        } else if (std.mem.eql(u8, key, "green")) {
            self.green = v;
        } else {
            self.blue = v;
        }
    }
};

const Game = struct { id: u32, plays: std.ArrayList(Play) };

fn parse(line: []const u8, game: *Game) !void {
    var colon_split = std.mem.split(u8, line, ": ");
    var game_str = colon_split.first();
    var plays_str = colon_split.rest();

    var game_str_split = std.mem.split(u8, game_str, " ");
    _ = game_str_split.first();

    game.*.id = try std.fmt.parseInt(u32, game_str_split.next().?, 10);

    var chunks = std.mem.split(u8, plays_str, "; ");
    while (chunks.next()) |chunk| {
        var play: Play = Play.create();

        var entries = std.mem.split(u8, chunk, ", ");
        while (entries.next()) |entry| {
            var tokens = std.mem.split(u8, entry, " ");
            var cnt = try std.fmt.parseInt(u32, tokens.next().?, 10);
            var key = tokens.next().?;
            play.set(key, cnt);
        }

        try game.plays.append(play);
    }
}
pub fn solve(allocator: std.mem.Allocator, input: []const u8, cb: *const fn (allocator: std.mem.Allocator, line: []const u8) Error!?u32) Error!u32 {
    var r: u32 = 0;
    var split = std.mem.split(u8, input, "\n");
    while (split.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (try cb(allocator, line)) |v| {
            r += v;
        }
    }

    return r;
}

fn handle1(allocator: std.mem.Allocator, line: []const u8) Error!?u32 {
    var game = Game{ .id = 0, .plays = std.ArrayList(Play).init(allocator) };
    defer game.plays.deinit();

    try parse(line, &game);

    for (game.plays.items) |play| {
        if (play.red > 12 or play.green > 13 or play.blue > 14) {
            return null;
        }
    }

    return game.id;
}

// #2

fn handle2(allocator: std.mem.Allocator, line: []const u8) Error!?u32 {
    var game = Game{ .id = 0, .plays = std.ArrayList(Play).init(allocator) };
    defer game.plays.deinit();

    try parse(line, &game);

    var needed = Play{ .red = 0, .green = 0, .blue = 0 };
    for (game.plays.items) |play| {
        needed.red = @max(needed.red, play.red);
        needed.green = @max(needed.green, play.green);
        needed.blue = @max(needed.blue, play.blue);
    }

    return needed.red * needed.green * needed.blue;
}

test "solution1" {
    var r = try solve(testing.allocator, @embedFile("input"), handle1);
    try testing.expectEqual(@as(u32, 2176), r);
}

test "solution2" {
    var r = try solve(testing.allocator, @embedFile("input"), handle2);
    try testing.expectEqual(@as(u32, 63700), r);
}
