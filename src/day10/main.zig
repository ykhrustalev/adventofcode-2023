const std = @import("std");
const testing = std.testing;

const Error = error{
    Overflow,
    OutOfMemory,
    InvalidCharacter,
    Malformed,
};

const Input = struct {
    lines: [][]const u8,

    pub fn parse(alloc: std.mem.Allocator, input: []const u8) !Input {
        var it = std.mem.split(u8, input, "\n");

        var arr = std.ArrayList([]const u8).init(alloc);
        defer arr.deinit();

        while (it.next()) |line| {
            if (line.len > 0) {
                try arr.append(line);
            }
        }

        return Input{ .lines = try arr.toOwnedSlice() };
    }
};

const Point = struct {
    row: usize,
    col: usize,

    pub fn value(self: *const Point, lines: [][]const u8) u8 {
        return lines[self.row][self.col];
    }

    pub fn is(self: *const ?Point, lines: [][]const u8, what: []const u8) bool {
        if (self.* == null) return false;
        return std.mem.indexOfScalar(u8, what, self.*.?.value(lines)) != null;
    }
};

fn get_start(lines: [][]const u8) Point {
    for (lines, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (c == 'S') {
                return Point{ .row = row, .col = col };
            }
        }
    }
    unreachable;
}

const Area = struct {
    const Self = @This();

    nw: ?Point,
    n: ?Point,
    ne: ?Point,
    w: ?Point,
    x: Point,
    e: ?Point,
    sw: ?Point,
    s: ?Point,
    se: ?Point,

    pub fn for_point(cur: Point, lines: [][]const u8) Self {
        const max_col = lines[0].len - 1;
        const max_row = lines.len - 1;

        var r = Self{
            .nw = null,
            .n = null,
            .ne = null,
            .w = null,
            .x = cur,
            .e = null,
            .sw = null,
            .s = null,
            .se = null,
        };

        if (cur.row > 0 and cur.col > 0) r.nw = Point{ .row = cur.row - 1, .col = cur.col - 1 };
        if (cur.row > 0) r.n = Point{ .row = cur.row - 1, .col = cur.col };
        if (cur.row > 0 and cur.col < max_col) r.ne = Point{ .row = cur.row - 1, .col = cur.col + 1 };
        if (cur.col > 0) r.w = Point{ .row = cur.row, .col = cur.col - 1 };
        if (cur.col < max_col) r.e = Point{ .row = cur.row, .col = cur.col + 1 };
        if (cur.row < max_row and cur.col > 0) r.sw = Point{ .row = cur.row + 1, .col = cur.col - 1 };
        if (cur.row < max_row) r.s = Point{ .row = cur.row + 1, .col = cur.col };
        if (cur.row < max_row and cur.col < max_col) r.se = Point{ .row = cur.row + 1, .col = cur.col + 1 };

        return r;
    }

    pub fn without(self: *const Self, p: Point) Area {
        var r: Self = self.*;
        if (r.ne != null and std.meta.eql(r.ne.?, p)) r.ne = null;
        if (r.n != null and std.meta.eql(r.n.?, p)) r.n = null;
        if (r.nw != null and std.meta.eql(r.nw.?, p)) r.nw = null;
        if (r.e != null and std.meta.eql(r.e.?, p)) r.e = null;
        if (r.w != null and std.meta.eql(r.w.?, p)) r.w = null;
        if (r.se != null and std.meta.eql(r.se.?, p)) r.se = null;
        if (r.s != null and std.meta.eql(r.s.?, p)) r.s = null;
        if (r.sw != null and std.meta.eql(r.sw.?, p)) r.sw = null;
        return r;
    }

    pub fn directions(self: *const Self, alloc: std.mem.Allocator, lines: [][]const u8, r: *std.ArrayList(Point)) !void {
        _ = alloc;
        switch (self.x.value(lines)) {
            '|' => {
                if (Point.is(&self.n, lines, "|7FS")) try r.append(self.n.?);
                if (Point.is(&self.s, lines, "|LJS")) try r.*.append(self.s.?);
            },
            '-' => {
                if (Point.is(&self.w, lines, "-LFS")) try r.*.append(self.w.?);
                if (Point.is(&self.e, lines, "-J7S")) try r.*.append(self.e.?);
            },
            'F' => {
                if (Point.is(&self.s, lines, "|JLS")) try r.*.append(self.s.?);
                if (Point.is(&self.e, lines, "-J7S")) try r.*.append(self.e.?);
            },
            '7' => {
                if (Point.is(&self.s, lines, "|JLS")) try r.*.append(self.s.?);
                if (Point.is(&self.w, lines, "-LFS")) try r.*.append(self.w.?);
            },
            'J' => {
                if (Point.is(&self.n, lines, "|7FS")) try r.*.append(self.n.?);
                if (Point.is(&self.w, lines, "-LFS")) try r.*.append(self.w.?);
            },
            'L' => {
                if (Point.is(&self.n, lines, "|7FS")) try r.*.append(self.n.?);
                if (Point.is(&self.e, lines, "-7JS")) try r.*.append(self.e.?);
            },
            'S' => {
                if (Point.is(&self.n, lines, "|7F")) try r.*.append(self.n.?);
                if (Point.is(&self.s, lines, "|JL")) try r.*.append(self.s.?);
                if (Point.is(&self.e, lines, "-J7")) try r.*.append(self.e.?);
                if (Point.is(&self.w, lines, "-FL")) try r.*.append(self.w.?);
            },
            else => {},
        }
    }
};

fn print_lines(lines: [][]const u8, p: Point) void {
    std.debug.print("\n", .{});
    for (lines, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (row == p.row and col == p.col) {
                std.debug.print("{c}", .{'@'});
                // std.debug.print(" ", .{});
            } else {
                std.debug.print("{c}", .{c});
                // std.debug.print(" ", .{});
            }
        }
        std.debug.print("\n", .{});
        // std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn walk(alloc: std.mem.Allocator, lines: [][]const u8, cur_: Point, prev_: Point, shape: *std.ArrayList(Point)) !void {
    var cur = cur_;
    var prev = prev_;
    var directions = std.ArrayList(Point).init(alloc);
    defer directions.deinit();

    while (true) {
        // print_lines(lines, cur);
        if (cur.value(lines) == 'S') {
            // std.debug.print("reached S {any}\n", .{cur});
            return;
        }

        var area = Area.for_point(cur, lines).without(prev);

        directions.clearRetainingCapacity();
        try area.directions(alloc, lines, &directions);

        if (directions.items.len == 0) {
            shape.clearAndFree();
            return;
        }

        if (directions.items.len != 1) {
            std.debug.print("prev={any}\n", .{prev});
            std.debug.print("next={any}\n", .{directions.items});
            unreachable;
        }

        try shape.append(cur);
        prev = cur;
        cur = directions.items[0];
    }
}

fn begin(alloc: std.mem.Allocator, lines: [][]const u8, cur: Point) !?[]Point {
    const area = Area.for_point(cur, lines);
    // print_lines(lines, cur);

    var directions = std.ArrayList(Point).init(alloc);
    try area.directions(alloc, lines, &directions);

    var longest_shape: ?[]Point = null;

    for (directions.items) |p| {
        var shape = std.ArrayList(Point).init(alloc);
        try shape.append(cur);

        std.debug.print("walking ... to {any}\n", .{p});
        try walk(alloc, lines, p, cur, &shape);
        if (longest_shape == null or longest_shape.?.len < shape.items.len) {
            longest_shape = try shape.toOwnedSlice();
        }
        shape.deinit();
    }

    return longest_shape;
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try Input.parse(arena.allocator(), input);
    const s = get_start(inputs.lines);

    const shape = try begin(arena.allocator(), inputs.lines, s);

    return if (shape == null) 0 else shape.?.len / 2;
}

fn count_intersections(line: []const u8, needle: []const u8) usize {
    // std.debug.print("{s} for {s}", .{ needle, line });
    var r: usize = 0;
    for (line) |c| {
        if (std.mem.indexOfScalar(u8, needle, c) != null) {
            r += 1;
        }
    }
    // std.debug.print(" cnt={}\n", .{r});
    return r;
}

fn count_intersections2(alloc: std.mem.Allocator, line: []const u8, needls: *std.StringHashMap(usize), replace: []const u8) !usize {
    // std.debug.print("{s} for {s}", .{ needle, line });
    var filtered = try alloc.dupe(u8, line);
    @memset(filtered, 0);
    defer alloc.free(filtered);

    _ = std.mem.replace(u8, line, replace, "", filtered[0..]);

    var cnt: usize = 0;
    var it = needls.*.iterator();
    while (it.next()) |i| {
        cnt += std.mem.count(u8, filtered, i.key_ptr.*) * i.value_ptr.*;
    }

    // std.debug.print(" {s}  {s}  cnt={}\n", .{ line, filtered, cnt });
    return cnt;
}

fn count_horizontal(alloc: std.mem.Allocator, line: []const u8) !usize {
    var needls = std.StringHashMap(usize).init(alloc);
    defer needls.deinit();
    try needls.put("F7", 2);
    try needls.put("LJ", 2);
    try needls.put("L7", 1);
    try needls.put("FJ", 1);
    try needls.put("|", 1);
    //  L--J.L7...LJF7F-7L7
    return count_intersections2(alloc, line, &needls, "-");
}

fn count_vertical(alloc: std.mem.Allocator, lines: [][]const u8, beg: usize, end: usize, col: usize) !usize {
    var lines_ = std.ArrayList(u8).init(alloc);
    defer lines_.deinit();

    for (beg..end) |i| {
        try lines_.append(lines[i][col]);
    }

    //
    // F  F  7  7
    // L  J  L  J
    //
    var needls = std.StringHashMap(usize).init(alloc);
    defer needls.deinit();
    try needls.put("FL", 2);
    try needls.put("7J", 2);
    try needls.put("FJ", 1);
    try needls.put("7L", 1);
    try needls.put("-", 1);
    return count_intersections2(alloc, lines_.items, &needls, "|");
}

fn belongs_inner(alloc: std.mem.Allocator, lines: [][]const u8, p: Point) !bool {
    var numbers = std.ArrayList(usize).init(alloc);
    defer numbers.deinit();

    const line = lines[p.row];

    // print_lines(lines, p);

    try numbers.append(try count_horizontal(alloc, line[0 .. p.col + 1]));
    try numbers.append(try count_horizontal(alloc, line[p.col..line.len]));
    try numbers.append(try count_vertical(alloc, lines, 0, p.row + 1, p.col));
    try numbers.append(try count_vertical(alloc, lines, p.row, lines.len, p.col));

    var has_non_null = false;
    var has_even = false;
    for (numbers.items) |n| {
        if (n != 0) {
            has_non_null = true;
        }
        if (n != 0 and n % 2 == 0) {
            has_even = true;
            break;
        }
    }
    var belongs = true;
    if (!has_non_null) {
        belongs = false;
    } else if (has_even) {
        belongs = false;
    }

    std.debug.print("{any} {any} belongs={}\n", .{ p, numbers.items, belongs });

    return belongs;
}

fn copy_paint(alloc: std.mem.Allocator, lines: [][]const u8, fill: u8) ![][]u8 {
    var arr = std.ArrayList([]u8).init(alloc);
    for (lines) |line| {
        var dup = try alloc.dupe(u8, line);
        @memset(dup, fill);
        try arr.append(dup);
    }
    return try arr.toOwnedSlice();
}

fn count_inner(alloc: std.mem.Allocator, lines: [][]const u8, start: Point, shape: []const Point) !usize {
    var painted = try copy_paint(alloc, lines, '.');
    for (shape) |p| painted[p.row][p.col] = lines[p.row][p.col];

    {
        var a = shape[1];
        var b = shape[shape.len - 1];

        var v: u8 = undefined;

        if (a.row > b.row) {
            std.mem.swap(Point, &b, &a);
        }

        if (a.row < b.row) {
            if (a.col < b.col) {
                if (start.col == a.col) {
                    // a
                    // sb
                    v = 'L';
                } else if (start.col == b.col) {
                    // as
                    //  b
                    v = '7';
                } else {
                    unreachable;
                }
            } else if (a.col == b.col) {
                // a
                // s
                // b
                v = '|';
            } else {
                if (start.col == a.col) {
                    //  a
                    // bs
                    v = 'J';
                } else if (start.col == b.col) {
                    // sa
                    // b
                    v = 'F';
                } else {
                    unreachable;
                }
            }
        } else if (a.row == b.row) {
            // asb
            v = '-';
        }

        painted[start.row][start.col] = v;
    }

    var cnt: usize = 0;

    print_lines(lines, Point{ .col = 9999, .row = 9999 });
    print_lines(painted, Point{ .col = 9999, .row = 9999 });

    for (painted, 0..) |line, row| {
        for (line, 0..) |c, col| {
            if (c == '.') {
                if (try belongs_inner(alloc, painted, Point{ .col = col, .row = row })) {
                    cnt += 1;
                }
            }
        }
    }

    return cnt;
}

pub fn solve2(allocator: std.mem.Allocator, input: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try Input.parse(arena.allocator(), input);
    const s = get_start(inputs.lines);

    const shape = (try begin(arena.allocator(), inputs.lines, s)).?;

    return count_inner(arena.allocator(), inputs.lines, s, shape);
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input-10"));
    try testing.expectEqual(@as(usize, 4), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(usize, 6831), r);
}

test "solution2 sample" {
    var r = try solve2(testing.allocator, @embedFile("input-20"));
    try testing.expectEqual(@as(usize, 4), r);
}

test "solution2 sample 2" {
    var r = try solve2(testing.allocator, @embedFile("input-21"));
    try testing.expectEqual(@as(usize, 8), r);
}
test "solution2 sample 3" {
    var r = try solve2(testing.allocator, @embedFile("input-22"));
    try testing.expectEqual(@as(usize, 10), r);
}

test "solution2" {
    var r = try solve2(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(usize, 305), r);
}
