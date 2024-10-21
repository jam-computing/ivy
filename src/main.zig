const std = @import("std");
const server = @import("server.zig").server;
const log = @import("log.zig");

pub fn main() !void {
    const s = server{ .port = 3000 };
    log.debug("Running Server", @src());
    try s.run();
}
