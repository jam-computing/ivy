const std = @import("std");
const zap = @import("zap");
const controller = @import("controller.zig").controller;
const init_error = @import("controller.zig").controller_init_error;
const song = @import("song.zig").song;
const log = @import("log.zig");

var CONTROLLER: controller = undefined;

pub const server = struct {
    port: u32,

    pub fn run(self: *const server) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();

        var listener = zap.HttpListener.init(.{
            .port = self.port,
            .on_request = on_request,
            .log = true,
        });

        // CONTROLLER = try controller.init();

        _ = try song.init(&allocator, 5, 5);

        try listener.listen();

        std.debug.print("Listening on 0.0.0.0:{}", .{self.port});

        zap.start(.{
            .threads = 2,
            .workers = 2,
        });
    }

    fn on_request(r: zap.Request) void {
        if (r.path) |path| {
            std.debug.print("PATH: {s}\n", .{path});
        }

        if (r.query) |query| {
            std.debug.print("QUERY: {s}\n", .{query});
        }

        r.sendBody("<html><body>server response</body></html>") catch |err| {
            std.debug.print("Could not respond to request: {}", .{err});
        };
    }
};
