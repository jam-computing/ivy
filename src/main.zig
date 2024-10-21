const std = @import("std");
const server = @import("server.zig").server;

pub fn main() !void {
    const s = server{ .port = 3000 };
    try s.run();
}
