const d01 = @import("day01/main.zig");
const d02 = @import("day02/main.zig");

test "basic add functionality" {
    @import("std").testing.refAllDecls(@This());
}
