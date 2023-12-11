const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

const Input = struct {
    const Instructions = struct {
        value: []const u8,

        pub fn parse(line: []const u8) Instructions {
            return Instructions{ .value = line };
        }

        const Iterator = struct {
            i: usize = 0,
            value: []const u8,
            pub fn next(self: *Iterator) ?u8 {
                const v = self.*.value[self.*.i];

                if (self.*.i == self.*.value.len - 1) {
                    self.*.i = 0;
                } else {
                    self.*.i += 1;
                }

                return v;
            }
        };

        pub fn iterator(self: *Instructions) Iterator {
            return Iterator{ .i = 0, .value = self.*.value };
        }
    };

    const Node = struct {
        value: []const u8,
        l_value: []const u8,
        r_value: []const u8,
        left: ?*Node = undefined,
        right: ?*Node = undefined,

        pub fn parse(alloc: std.mem.Allocator, line: []const u8) !*Node {
            const v = line[0..3];
            const l = line[7..10];
            const r = line[12..15];

            var p = try alloc.create(Node);
            p.*.value = v;
            p.*.l_value = l;
            p.*.r_value = r;
            p.*.left = null;
            p.*.right = null;
            return p;
        }

        pub fn direction(self: *Node, v: u8) ?*Node {
            return if (v == 'L') self.left else self.right;
        }
    };

    const Network = struct {
        nodes: std.StringHashMap(*Node),

        pub fn init(alloc: std.mem.Allocator) Network {
            return Network{ .nodes = std.StringHashMap(*Node).init(alloc) };
        }

        pub fn parse(self: *Network, alloc: std.mem.Allocator, it: *std.mem.SplitIterator(u8, .sequence)) !void {
            while (it.next()) |line| {
                if (line.len > 0) {
                    var p = try Node.parse(alloc, line);
                    try self.*.nodes.putNoClobber(p.value, p);
                }
            }

            var j = self.*.nodes.valueIterator();
            while (j.next()) |node| {
                node.*.left = self.*.nodes.get(node.*.l_value);
                node.*.right = self.*.nodes.get(node.*.r_value);
            }
        }
    };

    instructions: Instructions,
    network: Network,

    pub fn parse(alloc: std.mem.Allocator, input: []const u8) !Input {
        var it = std.mem.split(u8, input, "\n");
        var instructions = Instructions.parse(it.next().?);
        _ = it.next();

        var network = Network.init(alloc);
        try network.parse(alloc, &it);

        return Input{ .instructions = instructions, .network = network };
    }
};

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !u128 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try Input.parse(arena.allocator(), input);

    var p: *Input.Node = inputs.network.nodes.get("AAA").?;
    var cnt: u32 = 0;
    var it = inputs.instructions.iterator();
    while (it.next()) |inst| {
        cnt += 1;
        p = p.direction(inst).?;
        if (std.mem.eql(u8, p.*.value, "ZZZ")) {
            return cnt;
        }
    }

    return 0;
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !u128 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try Input.parse(arena.allocator(), input);

    var nodes = std.ArrayList(*Input.Node).init(arena.allocator());
    var it_nodes = inputs.network.nodes.valueIterator();
    while (it_nodes.next()) |n| {
        if (n.*.value[2] == 'A') {
            try nodes.append(n.*);
        }
    }

    var distances: []u128 = try arena.allocator().alloc(u128, nodes.items.len);
    for (nodes.items, 0..) |p, i| {
        distances[i] = get_cnt(&inputs, p);
    }

    return lcm_arr(u128, distances);
}

fn get_cnt(inputs: *Input, n: *Input.Node) u32 {
    var cnt: u32 = 0;
    var it = inputs.instructions.iterator();
    var p: *Input.Node = n;
    while (it.next()) |inst| {
        cnt += 1;
        p = p.direction(inst).?;
        if (p.*.value[2] == 'Z') {
            break;
        }
    }
    return cnt;
}

fn lcm_arr(comptime T: type, seq: []T) T {
    var r = seq[0];
    for (1..seq.len) |i| {
        r = lcm(T, r, seq[i]);
    }
    return r;
}

fn lcm(comptime T: type, a: T, b: T) T {
    return a / gcd(T, a, b) * b;
}

fn gcd(comptime T: type, aa: T, bb: T) T {
    var a = aa;
    var b = bb;
    if (a < b) {
        std.mem.swap(T, &a, &b);
    }

    while (b != 0) {
        a %= b;
        std.mem.swap(T, &a, &b);
    }

    return a;
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input-a"));
    try testing.expectEqual(@as(u128, 2), r);
}

test "solution1 sample 2" {
    var r = try solve1(testing.allocator, @embedFile("input-b"));
    try testing.expectEqual(@as(u128, 6), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u128, 19637), r);
}

test "solution2 sample" {
    var r = try solve2(testing.allocator, @embedFile("input-2a"));
    try testing.expectEqual(@as(u128, 6), r);
}

test "solution2" {
    var r = try solve2(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u128, 8811050362409), r);
}
