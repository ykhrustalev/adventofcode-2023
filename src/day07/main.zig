const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

pub fn get_char_weight(c: u8) u8 {
    return switch (c) {
        'A' => 14,
        'K' => 13,
        'Q' => 12,
        'J' => 11,
        'T' => 10,
        '9' => 9,
        '8' => 8,
        '7' => 7,
        '6' => 6,
        '5' => 5,
        '4' => 4,
        '3' => 3,
        '2' => 2,
        else => unreachable,
    };
}

pub fn get_char_weight_joker_one(c: u8) u8 {
    if (c == 'J') return 0;
    return get_char_weight(c);
}

const HandType = enum(u8) {
    Five = 7,
    Four = 6,
    FullHouse = 5,
    Three = 4,
    TwoPairs = 3,
    Pair = 2,
    One = 1,
};

const Hand = struct {
    const Self = @This();

    cards: []const u8,
    bid: u64,
    type_: HandType,
    use_joker: bool,

    pub fn create(alloc: std.mem.Allocator, cards: []const u8, bid: u64, with_joker: bool) !Self {
        const t = if (with_joker) try Self.calcTypeWithJoker(alloc, cards) else try Self.calcType(alloc, cards);
        return Self{ .cards = cards, .bid = bid, .type_ = t, .use_joker = with_joker };
    }

    fn calcType(alloc: std.mem.Allocator, cards: []const u8) !HandType {
        var m = std.AutoHashMap(u8, u8).init(alloc);
        defer m.deinit();
        for (cards) |c| {
            var v = m.get(c);
            if (v == null) {
                v = 1;
            } else {
                v.? += 1;
            }
            try m.put(c, v.?);
        }

        if (m.count() == 1) {
            return .Five;
        }

        if (m.count() == 2) {
            var it = m.valueIterator();
            var a = it.next().?;
            var b = it.next().?;

            if (a.* == 4 or b.* == 4) {
                return .Four;
            }

            if (a.* == 3 or b.* == 3) {
                return .FullHouse;
            }

            unreachable;
        }

        if (m.count() == 3) {
            var it = m.valueIterator();
            var a = it.next().?;
            var b = it.next().?;
            var c = it.next().?;

            if (a.* * b.* * c.* == 4) {
                return .TwoPairs;
            }
        }

        var it = m.valueIterator();
        while (it.next()) |cnt| {
            if (cnt.* == 3) {
                return .Three;
            }
        }

        var it2 = m.valueIterator();
        while (it2.next()) |cnt| {
            if (cnt.* == 2) {
                return .Pair;
            }
        }

        if (m.count() == 5) {
            return .One;
        }

        unreachable;
    }

    fn calcTypeWithJoker(alloc: std.mem.Allocator, cards: []const u8) !HandType {
        var t = try Hand.calcType(alloc, cards);

        var jokerCount = std.mem.count(u8, cards, "J");

        return switch (t) {
            HandType.Five => HandType.Five,
            HandType.Four => {
                if (jokerCount == 1) return HandType.Five;
                if (jokerCount == 4) return HandType.Five;
                return HandType.Four;
            },
            HandType.FullHouse => {
                if (jokerCount == 2) return HandType.Five;
                if (jokerCount == 3) return HandType.Five;
                return HandType.FullHouse;
            },
            HandType.Three => {
                if (jokerCount == 1) return HandType.Four;
                if (jokerCount == 3) return HandType.Four;
                return HandType.Three;
            },
            HandType.TwoPairs => {
                if (jokerCount == 1) return HandType.FullHouse;
                if (jokerCount == 2) return HandType.Four;
                return HandType.TwoPairs;
            },
            HandType.Pair => {
                if (jokerCount == 1) return HandType.Three;
                if (jokerCount == 2) return HandType.Three;
                return HandType.Pair;
            },
            HandType.One => {
                if (jokerCount == 1) return HandType.Pair;
                return HandType.One;
            },
        };
    }

    fn lessThan(ctx: void, lhs: Hand, rhs: Hand) bool {
        _ = ctx;
        if (@intFromEnum(lhs.type_) < @intFromEnum(rhs.type_)) {
            return true;
        }
        if (@intFromEnum(lhs.type_) > @intFromEnum(rhs.type_)) {
            return false;
        }

        for (lhs.cards, rhs.cards) |l, r| {
            if (l == r) {
                continue;
            }
            if (lhs.use_joker) {
                return get_char_weight_joker_one(l) < get_char_weight_joker_one(r);
            }
            return get_char_weight(l) < get_char_weight(r);
        }

        unreachable;
    }
};

fn parseHand(alloc: std.mem.Allocator, line: []const u8, with_joker: bool) !Hand {
    var it = std.mem.split(u8, line, " ");
    const cards = it.next().?;
    const bidstr = it.rest();
    return Hand.create(alloc, cards, try std.fmt.parseInt(u64, bidstr, 10), with_joker);
}

const Input = struct {
    hands: []Hand,
};

fn parseInput(alloc: std.mem.Allocator, input: []const u8, with_joker: bool) !Input {
    var hands = std.ArrayList(Hand).init(alloc);

    var it = std.mem.split(u8, input, "\n");
    while (it.next()) |line| {
        if (line.len > 0) {
            try hands.append(try parseHand(alloc, line, with_joker));
        }
    }

    return Input{ .hands = try hands.toOwnedSlice() };
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8, with_joker: bool) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try parseInput(arena.allocator(), input, with_joker);

    std.mem.sort(Hand, inputs.hands, void{}, Hand.lessThan);

    var r: u64 = 0;

    for (inputs.hands, 1..) |hand, i| {
        r += hand.bid * i;
    }

    return r;
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input0"), false);
    try testing.expectEqual(@as(u64, 6440), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"), false);
    try testing.expectEqual(@as(u64, 252295678), r);
}

test "solution2 sample" {
    var r = try solve1(testing.allocator, @embedFile("input0"), true);
    try testing.expectEqual(@as(u64, 5905), r);
}

test "solution2 " {
    var r = try solve1(testing.allocator, @embedFile("input"), true);
    try testing.expectEqual(@as(u64, 250577259), r);
}
