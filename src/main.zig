const std = @import("std");
const server = @import("server.zig").server;
const log = @import("log.zig");
const rgb = @import("song.zig").rgb;

pub fn main() !void {
    try log.setup_log(log.log_level.info);
    const s = server{ .port = 3000 };
    log.log(@src(), .{ "Running on port", s.port, .info });
    try s.run();
}
