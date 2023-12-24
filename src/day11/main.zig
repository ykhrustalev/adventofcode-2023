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

fn get_empty_rows(lines: [][]const u8, output: *std.AutoHashMap(usize, void)) !void {
    for (lines, 0..) |line, row|
        if (std.mem.count(u8, line, "#") == 0)
            try output.*.put(row, void{});
}

fn get_empty_cols(lines: [][]const u8, output: *std.AutoHashMap(usize, void)) !void {
    for (0..lines[0].len) |col| {
        var has_v = false;
        for (lines) |line| {
            if (line[col] != '.') {
                has_v = true;
                break;
            }
        }
        if (!has_v)
            try output.*.put(col, void{});
    }
}

fn print_lines(lines: [][]const u8) void {
    std.debug.print("\n", .{});
    for (lines) |line| {
        std.debug.print("{s}\n", .{line});
    }
    std.debug.print("\n", .{});
}

fn extend(alloc: std.mem.Allocator, lines: [][]const u8, points: *std.ArrayList(Point), ext: usize) !void {
    var cols = std.AutoHashMap(usize, void).init(alloc);
    var rows = std.AutoHashMap(usize, void).init(alloc);

    try get_empty_rows(lines, &rows);
    try get_empty_cols(lines, &cols);

    var row_offset: usize = 0;
    for (lines, 0..) |line, row| {
        var col_offset: usize = 0;
        if (rows.contains(row)) {
            row_offset += ext;
            continue;
        }
        for (line, 0..) |c, col| {
            if (cols.contains(col)) {
                col_offset += ext;
                continue;
            }

            if (c == '#') {
                const eff_row = row + row_offset;
                const eff_col = col + col_offset;
                try points.*.append(Point{ .row = eff_row, .col = eff_col });
            }
        }
    }

    // print_lines(extended.items);

}

const Point = struct {
    row: usize,
    col: usize,
};

fn abs_diff(a: usize, b: usize) usize {
    return if (a < b) b - a else a - b;
}

fn find_paths(points: std.ArrayList(Point)) !usize {
    var r: usize = 0;
    for (0..points.items.len - 1) |i| {
        for (i + 1..points.items.len) |j| {
            const a = points.items[i];
            const b = points.items[j];
            const diff = abs_diff(a.col, b.col) + abs_diff(a.row, b.row);

            // std.debug.print("{any} {any} {}\n", .{ a, b, diff });
            r += diff;
        }
    }
    return r;
}
pub fn solve1(allocator: std.mem.Allocator, input: []const u8, ext: usize) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    var inputs = try Input.parse(arena.allocator(), input);

    var points = std.ArrayList(Point).init(arena.allocator());
    try extend(arena.allocator(), inputs.lines, &points, ext);

    return find_paths(points);
}

test "solution1 sample" {
    var r = try solve1(testing.allocator, @embedFile("input-10"), 1);
    try testing.expectEqual(@as(usize, 374), r);
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"), 1);
    try testing.expectEqual(@as(usize, 9274989), r);
}

test "solution2 sample" {
    var r = try solve1(testing.allocator, @embedFile("input"), 1000000 - 1);
    try testing.expectEqual(@as(usize, 10), r);
}
