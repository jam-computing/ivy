const std = @import("std");
const zap = @import("zap");
const controller = @import("controller.zig").controller;
const init_error = @import("controller.zig").controller_init_error;
const song = @import("song.zig").song;
const log = @import("stardust").sdlog;

var CONTROLLER: controller = undefined;

pub const server = struct {
    port: u32,

    pub fn run(self: *const server) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();

        var listener = zap.HttpListener.init(.{
            .port = self.port,
            .on_request = on_request,
        });

        // CONTROLLER = try controller.init();

        _ = try song.init(&allocator, 5, 5);

        log(@src(), .{ "Listening for incoming connections...", .info });

        try listener.listen();

        log(@src(), .{ "Started server...", .debug });

        zap.start(.{
            .threads = 2,
            .workers = 2,
        });
    }

    fn on_request(r: zap.Request) void {
        if (r.path) |path| {
            if (!std.mem.eql(u8, path, "/api")) {
                return;
            }
        }

        if (r.query) |query| {
            log(@src(), .{ "query:", query, .info });
        }

        r.sendBody("response") catch {
            log(@src(), .{ "Could not respond to request", .fatal });
        };
    }
};
