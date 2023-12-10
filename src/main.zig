const d01 = @import("day01/main.zig");
const d02 = @import("day02/main.zig");
const d03 = @import("day03/main.zig");
const d04 = @import("day04/main.zig");
const d05 = @import("day05/main.zig");
const d06 = @import("day06/main.zig");

test "basic add functionality" {
    @import("std").testing.refAllDecls(@This());
}
