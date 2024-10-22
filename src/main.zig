const std = @import("std");
const server = @import("server.zig").server;
const log = @import("log.zig");
const rgb = @import("song.zig").rgb;

pub fn main() !void {
    const str = "ff";
    const col = try rgb.atoc(str);

    std.debug.print("red: {}", .{col.red});
    std.debug.print("green: {}", .{col.green});
    std.debug.print("blue: {}", .{col.blue});

    const s = server{ .port = 3000 };
    log.debug("Running Server", @src());
    try s.run();
}
