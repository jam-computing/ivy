const std = @import("std");
const zap = @import("zap");
const controller = @import("controller.zig").controller;
const init_error = @import("controller.zig").controller_init_error;
const song = @import("song.zig").song;
const log = @import("stardust").sdlog;
const db = @import("database.zig").database;
const tree = @import("tree.zig").tree;

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

        log(@src(), .{ "Listening for incoming connections...", .info });

        try listener.listen();

        log(@src(), .{ "Started server...", .debug });

        db.init(alloc.?);

        log(@src(), .{ "Initiated database", .info });

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
            defer endpoints.deinit();
            while (it.next()) |x| {
                endpoints.append(x) catch {};
            }

            if (endpoints.items.len == 0 or endpoints.items[0].len == 0) {
                return;
            }

            if (std.mem.eql(u8, endpoints.items[0], "tree")) {
                handle_tree_request(&r, .{ .task = alloc.?.dupe(u8, endpoints.items[1]) catch "error" });
            } else if (std.mem.eql(u8, endpoints.items[0], "song")) {
                if (endpoints.items.len > 2) {
                    handle_song_request(r, .{ .task = alloc.?.dupe(u8, endpoints.items[1]) catch "error", .id = alloc.?.dupe(u8, endpoints.items[2]) catch "-1"});
                } else {
                    handle_song_request(r, .{ .task = alloc.?.dupe(u8, endpoints.items[1]) catch "error", .id = null });
                }
            } else if (std.mem.eql(u8, endpoints.items[0], "beat")) {
                handle_beat_request(r, &endpoints);
            } else if (std.mem.eql(u8, endpoints.items[0], "config")) {
                handle_config_request(r, &endpoints);
            }
        }

        if (r.query) |query| {
            log(@src(), .{ "query:", query, .info });
        }
    }

    fn handle_tree_request(r: *const zap.Request, args: struct { task: []const u8 }) void {
        // create, get
        if (std.mem.eql(u8, args.task, "create")) {
            if (r.body) |body| {
                log(@src(), .{ body, .info });
                const parsed = std.json.parseFromSlice(tree, alloc.?, body, .{}) catch |e| {
                    log(@src(), .{ "Could not create json. Please check valid json passed", .err });
                    log(@src(), .{ body, .info });
                    r.sendError(e, null, 505);
                    return;
                };

                log(@src(), .{ "Parsed data name:", parsed.value.name, .debug });
                r.sendBody("Create tree endpoint") catch {
                    log(@src(), .{ "Could not respond to request", .err });
                };
            }
        } else if (std.mem.eql(u8, args.task, "get")) {
            const trees = db.get_all_trees() catch {
                return;
            };
            if (trees) |t| blk: {
                var string = std.ArrayList(u8).init(alloc.?);
                std.json.stringify(t, .{}, string.writer()) catch {
                    log(@src(), .{ "Could not properly stringify data", .err });
                    break :blk;
                };
                r.sendBody(string.items) catch {
                    log(@src(), .{ "Could not respond to request", .err });
                };
            }
        } else {
            log(@src(), .{ "Invalid Task:", args.task, .err });
        }
    }
    fn handle_song_request(r: zap.Request, args: struct { task: []const u8, id: ?[]const u8 }) void {
        // get, play
        if (std.mem.eql(u8, args.task, "get")) {
            if (args.id) |_| {
                return;
            }

            log(@src(), .{ "Getting all songs", .info });

            const songs = db.get_all_songs() catch {
                return;
            };

            if (songs == null) {
                return;
            }

            var string = std.ArrayList(u8).init(alloc.?);

            std.json.stringify(songs.?, .{}, string.writer()) catch |e| {
                log(@src(), .{ "Could not properly stringify data", .err });
                r.sendError(e, null, 505);
                return;
            };
            r.sendBody(string.items) catch {
                log(@src(), .{ "Could not respond to request", .err });
                return;
            };
        }
    }
    fn handle_beat_request(r: zap.Request, _: *const std.ArrayList([]const u8)) void {
        // play
        r.sendBody("Beat endpoint") catch {
            log(@src(), .{ "Could not respond to request", .fatal });
        };
    }
    fn handle_config_request(r: zap.Request, _: *const std.ArrayList([]const u8)) void {
        // none
        r.sendBody("Config endpoint") catch {
            log(@src(), .{ "Could not respond to request", .fatal });
        };
    }
};
