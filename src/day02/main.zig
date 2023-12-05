const std = @import("std");
const testing = std.testing;

const Error = error{ OutOfMemory, NoHeader, Malformed };

fn _add(cnt: *i32, v: u32) bool {
    cnt.* -= @as(i32, @intCast(v));
    return cnt.* >= 0;
}

const Bucket = struct {
    red: i32,
    green: i32,
    blue: i32,

    pub fn add(self: *Bucket, key: []const u8, cnt: u32) !bool {
        if (std.mem.eql(u8, key, "red")) {
            return _add(&self.red, cnt);
        } else if (std.mem.eql(u8, key, "green")) {
            return _add(&self.green, cnt);
        } else {
            return _add(&self.blue, cnt);
        }
    }
};

fn full_bucket() Bucket {
    return Bucket{ .red = 12, .green = 13, .blue = 14 };
}

fn to_chunks(allocator: std.mem.Allocator, text: []const u8, sep: []const u8) ![][]const u8 {
    var buf = std.ArrayList([]const u8).init(allocator);
    defer buf.deinit();

    var p = text[0..];
    while (std.mem.indexOf(u8, p, sep)) |pos| {
        var c = p[0..pos];
        try buf.append(c);
        p = p[pos + 1 ..];
    }
    if (p.len > 0) {
        try buf.append(p);
    }

    return buf.toOwnedSlice();
}

fn is_ok(allocator: std.mem.Allocator, line: []const u8) !?u32 {
    if (std.mem.indexOf(u8, line, ":")) |colon_pos| {
        var id: u32 = try std.fmt.parseInt(u32, line[5..colon_pos], 10);
        std.debug.print("{d}\n", .{id});

        var chunks = try to_chunks(allocator, line[colon_pos + 1 ..], ";");
        defer allocator.free(chunks);

        for (chunks) |chunk| {
            std.debug.print("{s}\n", .{chunk});

            var items = try to_chunks(allocator, chunk, ",");
            defer allocator.free(items);

            var bucket = full_bucket();

            for (items) |item_| {
                var item = item_[1..];

                var space_pos = std.mem.indexOf(u8, item, " ");
                if (space_pos == null) {
                    return Error.Malformed;
                }

                var cnt = try std.fmt.parseInt(u32, item[0..space_pos.?], 10);
                var name = item[space_pos.? + 1 ..];

                std.debug.print(" {s}: {d}\n", .{ name, cnt });

                if (!try bucket.add(name, cnt)) {
                    std.debug.print(" no\n", .{});

                    return null;
                }
            }
        }

        return id;
    } else {
        return Error.NoHeader;
    }
}

pub fn solve1(allocator: std.mem.Allocator, input: []const u8) !u32 {
    var splits = std.mem.split(u8, input, "\n");

    var r: u32 = 0;
    while (splits.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (try is_ok(allocator, line)) |v| {
            r += v;
        }
    }

    return r;
}

test "solution1" {
    var r = try solve1(testing.allocator, @embedFile("input"));
    try testing.expectEqual(@as(u32, 2176), r);
}
