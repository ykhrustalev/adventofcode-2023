const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

const Token = struct {
    beg: usize,
    end: usize,

    value: u32,

    const Iterator = struct {
        line: []const u8,
        index: usize,

        pub fn next(self: *Iterator) ?Token {
            var accumulating = false;
            var r = Token{ .beg = 0, .end = 0, .value = 0 };

            if (self.index >= self.line.len - 1) {
                return null;
            }

            for (self.line[self.index..], self.index..) |c, i| {
                if (!std.ascii.isDigit(c)) {
                    self.index = i;
                    if (accumulating) {
                        r.value = std.fmt.parseInt(u32, self.line[r.beg .. r.end + 1], 10) catch unreachable;
                        return r;
                    }
                    continue;
                }

                if (!accumulating) {
                    accumulating = true;
                    r.beg = i;
                }
                r.end = i;
                self.index = i;
            }

            if (accumulating) {
                r.value = std.fmt.parseInt(u32, self.line[r.beg .. r.end + 1], 10) catch unreachable;
                return r;
            }

            return null;
        }
    };

    pub fn iter(line: []const u8) Iterator {
        return Iterator{ .line = line, .index = 0 };
    }
};

fn is_symbol(c: u8) bool {
    return !std.ascii.isDigit(c) and c != '.';
}

fn is_attached(area: [][]const u8, row: usize, token: Token) bool {
    const left = if (token.beg > 0) token.beg - 1 else token.beg;
    const right = if (token.end >= area[row].len - 1) area[row].len else token.end + 2;

    if (row > 0) {
        for (area[row - 1][left..right]) |c| {
            if (is_symbol(c)) {
                return true;
            }
        }
    }

    if (token.beg > 0) {
        if (is_symbol(area[row][token.beg - 1])) {
            return true;
        }
    }

    if (token.end < area[row].len - 1) {
        if (is_symbol(area[row][token.end + 1])) {
            return true;
        }
    }

    if (row < area.len - 1) {
        for (area[row + 1][left..right]) |c| {
            if (is_symbol(c)) {
                return true;
            }
        }
    }

    return false;
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var r: u32 = 0;

    var area = std.ArrayList([]const u8).init(allocator);
    defer area.deinit();

    var split = std.mem.split(u8, input, "\n");
    while (split.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        try area.append(line);
    }

    for (area.items, 0..) |line, row| {
        var it = Token.iter(line);
        while (it.next()) |token| {
            if (is_attached(area.items, row, token)) {
                r += token.value;
            }
        }
    }

    return r;
}

const Point = struct {
    row: usize,
    col: usize,
};

const GearMap = struct {
    m: std.AutoHashMap(Point, std.AutoHashMap(Token, void)),

    pub fn init(allocator: std.mem.Allocator) GearMap {
        return GearMap{ .m = std.AutoHashMap(Point, std.AutoHashMap(Token, void)).init(allocator) };
    }

    pub fn deinit(self: *GearMap) void {
        var it = self.*.m.valueIterator();
        while (it.next()) |v| {
            v.*.deinit();
        }
        self.*.m.deinit();
    }

    pub fn add(self: *GearMap, allocator: std.mem.Allocator, p: Point, t: Token) !void {
        var v = self.*.m.get(p);
        if (v == null) {
            v = std.AutoHashMap(Token, void).init(allocator);
        }
        try v.?.put(t, void{});
        try self.*.m.put(p, v.?);
    }
};

fn link_gear(allocator: std.mem.Allocator, area: [][]const u8, row: usize, token: Token, gear_map: *GearMap) !void {
    const left = if (token.beg > 0) token.beg - 1 else token.beg;
    const right = if (token.end >= area[row].len - 1) area[row].len else token.end + 2;

    if (row > 0) {
        for (left..right) |col| {
            if (area[row - 1][col] == '*') {
                try gear_map.*.add(allocator, Point{ .col = col, .row = row - 1 }, token);
            }
        }
    }

    if (token.beg > 0) {
        if (area[row][token.beg - 1] == '*') {
            try gear_map.*.add(allocator, Point{ .col = token.beg - 1, .row = row }, token);
        }
    }

    if (token.end < area[row].len - 1) {
        if (area[row][token.end + 1] == '*') {
            try gear_map.*.add(allocator, Point{ .col = token.end + 1, .row = row }, token);
        }
    }

    if (row < area.len - 1) {
        for (left..right) |col| {
            if (area[row + 1][col] == '*') {
                try gear_map.*.add(allocator, Point{ .col = col, .row = row + 1 }, token);
            }
        }
    }
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var area = std.ArrayList([]const u8).init(allocator);
    defer area.deinit();

    var split = std.mem.split(u8, input, "\n");
    while (split.next()) |line| {
        if (line.len > 0) {
            try area.append(line);
        }
    }

    var gears_map = GearMap.init(allocator);
    defer gears_map.deinit();

    for (area.items, 0..) |line, row| {
        var it = Token.iter(line);
        while (it.next()) |token| {
            try link_gear(allocator, area.items, row, token, &gears_map);
        }
    }

    var r: u32 = 0;

    var it = gears_map.m.iterator();
    while (it.next()) |e| {
        if (e.value_ptr.*.count() != 2) {
            continue;
        }

        var prod: u32 = 1;
        var tokens = e.value_ptr.*.keyIterator();
        while (tokens.next()) |token| {
            prod *= token.value;
        }
        r += prod;
    }

    return r;
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u32, 4361), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u32, 538046), r);
}

test "solution2 sample" {
    var r = try solve2(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u32, 467835), r);
}

test "solution2" {
    var r = try solve2(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u32, 467835), r);
}
