const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

const Map = struct {
    const Self = @This();

    const Range = struct {
        src: u64,
        dst: u64,
        interval: u64,

        fn get(self: *const Range, v: u64) ?u64 {
            if (v >= self.*.src and v < self.*.src + self.*.interval) {
                return v - self.*.src + self.*.dst;
            }
            return null;
        }
    };

    ranges: std.ArrayList(Range),
    next: ?*Self,

    pub fn create(alloc: std.mem.Allocator) !*Self {
        var m = try alloc.create(Self);
        m.*.ranges = std.ArrayList(Range).init(alloc);
        m.*.next = null;
        return m;
    }

    pub fn get(self: *Self, v: u64) u64 {
        for (self.ranges.items) |range| {
            if (range.get(v)) |resolved| {
                return resolved;
            }
        }
        return v;
    }

    pub fn add_range(self: *Self, dst: u64, src: u64, interval: u64) !void {
        try self.*.ranges.append(Range{ .dst = dst, .src = src, .interval = interval });
    }
};

const Inputs = struct {
    const Self = @This();

    seeds: std.ArrayList(u64),
    head: ?*Map,

    pub fn add_map(self: *Self, allocator: std.mem.Allocator) !*Map {
        var m = try Map.create(allocator);

        if (self.head == null) {
            self.head = m;
            return m;
        }

        var p = self.head;
        while (true) {
            if (p.?.next == null) {
                p.?.next = m;
                return m;
            }
            p = p.?.next;
        }
    }

    const SeedRange = struct {
        beg: u64,
        interval: u64,
    };

    pub fn seeds_from_ranges(self: *Self, alloc: std.mem.Allocator) ![]SeedRange {
        var r = std.ArrayList(SeedRange).init(alloc);

        var i: usize = 0;
        while (i < self.*.seeds.items.len) : (i += 2) {
            const beg = self.*.seeds.items[i];
            const interval = self.*.seeds.items[i + 1];
            try r.append(SeedRange{ .beg = beg, .interval = interval });
        }

        return r.toOwnedSlice();
    }

    pub fn get(self: *Self, seed: u64) u64 {
        std.debug.assert(self.*.head != null);

        var v = seed;
        var p = self.*.head;
        while (p != null) {
            v = p.?.get(v);
            p = p.?.next;
        }

        return v;
    }
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Inputs {
    var inputs = Inputs{ .seeds = std.ArrayList(u64).init(allocator), .head = null };

    var cur_map: ?*Map = null;

    var it = std.mem.split(u8, input, "\n");
    while (it.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (std.ascii.startsWithIgnoreCase(line, "seeds")) {
            var split = std.mem.split(u8, line, ": ");
            _ = split.next();
            var it1 = std.mem.split(u8, split.rest(), " ");
            while (it1.next()) |v| {
                if (v.len > 0) {
                    try inputs.seeds.append(try std.fmt.parseInt(u64, v, 10));
                }
            }
            continue;
        }

        if (std.ascii.indexOfIgnoreCasePos(line, 0, " map:") != null) {
            cur_map = try inputs.add_map(allocator);
            continue;
        }

        var it2 = std.mem.split(u8, line, " ");

        try cur_map.?.*.add_range(
            try std.fmt.parseInt(u64, it2.next().?, 10),
            try std.fmt.parseInt(u64, it2.next().?, 10),
            try std.fmt.parseInt(u64, it2.next().?, 10),
        );
    }
    return inputs;
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try parseInput(arena.allocator(), input);

    var r: ?u64 = null;

    for (inputs.seeds.items) |seed| {
        var v = inputs.get(seed);
        if (r == null or v < r.?) {
            r = v;
        }
    }

    if (r != null) {
        return r.?;
    }

    return 0;
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !u64 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try parseInput(arena.allocator(), input);

    var r: ?u64 = null;

    var seeds_ranges = try inputs.seeds_from_ranges(arena.allocator());
    for (seeds_ranges) |range| {
        std.debug.print("{} - {}\n", .{range.beg, range.interval});
        for (range.beg..range.beg + range.interval) |seed| {
            if (seed % 100000 == 0){
                std.debug.print(" {}\n", .{seed});
            }
            var v = inputs.get(seed);
            if (r == null or v < r.?) {
                r = v;
            }
        }
    }

    if (r != null) {
        return r.?;
    }

    return 0;
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u64, 35), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u64, 107430936), r);
}

test "solution2 sample" {
    var r = try solve2(testing.allocator, @embedFile("input0"));
    try testing.expectEqual(@as(u64, 46), r);
}

test "solution2 " {
    var r = try solve2(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u64, 23738616), r);
}
