const std = @import("std");
const server = @import("server.zig").server;
const sd = @import("stardust");
const rgb = @import("song.zig").rgb;

pub fn main() !void {
    try sd.sd_init_log(sd.sd_log_level.info, null);
    const s = server{ .port = 3000 };
    sd.sdlog(@src(), .{ "Running on port", s.port, .info });
    try s.run();
}
