const std = @import("std");
const server = @import("server.zig").server;
const log = @import("log.zig");
const rgb = @import("song.zig").rgb;

pub fn main() !void {
    try log.setup_log();
    const s = server{ .port = 3000 };
    log.debug("Running Server on port: {}", .{@src(), s.port});
    try s.run();
}
