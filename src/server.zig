const std = @import("std");
const zap = @import("zap");
const controller = @import("controller.zig").controller;
const init_error = @import("controller.zig").controller_init_error;
const song = @import("song.zig").song;
const log = @import("stardust").sdlog;

var CONTROLLER: controller = undefined;

var alloc: ?std.mem.Allocator = null;

pub const server = struct {
    port: u32,

    pub fn run(self: *const server) !void {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        alloc = gpa.allocator();

        var listener = zap.HttpListener.init(.{
            .port = self.port,
            .on_request = on_request,
        });

        // CONTROLLER = try controller.init();

        _ = try song.init(&alloc.?, 5, 5);

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
            if (alloc) |_| {} else {
                log(@src(), .{ "Alloc was not initialised", .fatal });
                return;
            }

            var it = std.mem.splitAny(u8, path[1..], "/");
            if (!std.mem.eql(u8, it.first(), "api")) {
                r.sendBody("please hit /api instead") catch {
                    log(@src(), .{ "Could not respond to request", .fatal });
                };
                return;
            }

            var endpoints = std.ArrayList([]const u8).init(alloc.?);
            while (it.next()) |x| {
                endpoints.append(x) catch {};
            }

            if (endpoints.items.len == 0 or endpoints.items[0].len == 0) {
                return;
            }

            if (std.mem.eql(u8, endpoints.items[0], "tree")) {
                handle_tree_request(r, endpoints.items);
            } else if (std.mem.eql(u8, endpoints.items[0], "song")) {
                handle_song_request(r, endpoints.items);
            } else if (std.mem.eql(u8, endpoints.items[0], "beat")) {
                handle_beat_request(r, endpoints.items);
            } else if (std.mem.eql(u8, endpoints.items[0], "config")) {
                handle_config_request(r, endpoints.items);
            }
        }

        if (r.query) |query| {
            log(@src(), .{ "query:", query, .info });
        }
    }

    fn handle_tree_request(r: zap.Request, _: [][]const u8) void {
        r.sendBody("Tree endpoint") catch {
            log(@src(), .{ "Could not respond to request", .fatal });
        };
    }
    fn handle_song_request(r: zap.Request, _: [][]const u8) void {
        r.sendBody("Song endpoint") catch {
            log(@src(), .{ "Could not respond to request", .fatal });
        };
    }
    fn handle_beat_request(r: zap.Request, _: [][]const u8) void {
        r.sendBody("Beat endpoint") catch {
            log(@src(), .{ "Could not respond to request", .fatal });
        };
    }
    fn handle_config_request(r: zap.Request, _: [][]const u8) void {
        r.sendBody("Config endpoint") catch {
            log(@src(), .{ "Could not respond to request", .fatal });
        };
    }
};
