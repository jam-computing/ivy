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

const creation_response = struct { success: bool };

pub const creation_song_request = struct {
    name: []const u8,
    author: []const u8,
    beats: [][][]const u8,
};

pub const play_song_request = struct { id: i32 };

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
                    handle_song_request(r, .{ .task = alloc.?.dupe(u8, endpoints.items[1]) catch "error", .id = alloc.?.dupe(u8, endpoints.items[2]) catch "-1" });
                } else {
                    handle_song_request(r, .{ .task = alloc.?.dupe(u8, endpoints.items[1]) catch "error", .id = null });
                }
            } else if (std.mem.eql(u8, endpoints.items[0], "beat")) {
                if (endpoints.items.len > 1) {
                    handle_beat_request(r, .{ .task = alloc.?.dupe(u8, endpoints.items[1]) catch "error" });
                } else {
                    r.sendBody("Please hit api/beat/play with json") catch |e| {
                        log(@src(), .{ "could not reply to beat play request", .err });
                        r.sendError(e, null, 505);
                        return;
                    };
                }
            } else if (std.mem.eql(u8, endpoints.items[0], "config")) {
                handle_config_request(r);
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
            const trees = db.get_all_trees() catch |e| {
                log(@src(), .{ "Could not get all trees", .debug });
                r.sendError(e, null, 505);
                return;
            };
            if (trees) |t| blk: {
                var string = std.ArrayList(u8).init(alloc.?);
                std.json.stringify(t, .{}, string.writer()) catch {
                    log(@src(), .{ "Could not properly stringify data", .err });
                    break :blk;
                };
                r.sendJson(string.items) catch {
                    log(@src(), .{ "Could not respond to request", .err });
                };
            }
        } else if (std.mem.eql(u8, args.task, "meta")) {
            const trees = db.get_all_trees_names() catch |e| {
                log(@src(), .{ "Could not get all trees", .debug });
                r.sendError(e, null, 505);
                return;
            };
            if (trees) |t| blk: {
                var string = std.ArrayList(u8).init(alloc.?);
                std.json.stringify(t, .{}, string.writer()) catch {
                    log(@src(), .{ "Could not properly stringify data", .err });
                    break :blk;
                };
                r.sendJson(string.items) catch {
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
            if (args.id) |id| {
                const s = db.get_song(std.fmt.parseInt(i32, id, 10) catch -1) catch return;

                if (s == null) {
                    return;
                }

                var string = std.ArrayList(u8).init(alloc.?);

                std.json.stringify(s.?, .{}, string.writer()) catch |e| {
                    log(@src(), .{ "Could not properly stringify data", .err });
                    r.sendError(e, null, 505);
                    return;
                };

                r.sendJson(string.items) catch |e| {
                    log(@src(), .{ "Could not respond to request", .err });
                    r.sendError(e, null, 505);
                };
                return;
            }

            log(@src(), .{ "Getting all songs", .info });

            const songs = db.get_all_songs() catch {
                r.sendBody("could not get all songs") catch |e| {
                    r.sendError(e, null, 505);
                };
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
            r.sendJson(string.items) catch |e| {
                log(@src(), .{ "Could not respond to request", .err });
                r.sendError(e, null, 505);
                return;
            };
        } else if (std.mem.eql(u8, args.task, "play")) {
            // expected input
            if (r.body) |body| {
                const parsed = std.json.parseFromSlice(play_song_request, alloc.?, body, .{}) catch |e| {
                    log(@src(), .{ "Could not create json. Please check valid json passed", .err });
                    log(@src(), .{ body, .info });
                    r.sendError(e, null, 505);
                    return;
                };

                log(@src(), .{ "id:", parsed.value.id, .info });
                const s = db.get_song(parsed.value.id) catch {
                    log(@src(), .{ "could not get song from db.", .err });
                    r.sendJson("{ \"success\": false") catch |e| {
                        log(@src(), .{ "could not send json", .err });
                        r.sendError(e, null, 505);
                    };
                    return;
                };

                if (s) |_song| {
                    CONTROLLER.play(&_song);
                    log(@src(), .{ "playing song", .err });
                } else {
                    log(@src(), .{ "not playing song", .err });
                    r.sendJson("{ \"success\": false") catch |e| {
                        log(@src(), .{ "could not send json", .err });
                        r.sendError(e, null, 505);
                    };
                }

                r.sendJson("{ \"success\": true") catch |e| {
                    log(@src(), .{ "could not send json", .err });
                    r.sendError(e, null, 505);
                };
            }
        } else if (std.mem.eql(u8, args.task, "meta")) {
            const songs = db.get_all_songs_names() catch {
                r.sendBody("could not get all songs") catch |e| {
                    log(@src(), .{ "Could not get metadata of all songs", .err });
                    r.sendError(e, null, 505);
                };
                return;
            };

            if (songs == null) {
                log(@src(), .{ "Could not get metadata of all songs", .err });
                return;
            }

            var string = std.ArrayList(u8).init(alloc.?);

            std.json.stringify(songs.?, .{}, string.writer()) catch |e| {
                log(@src(), .{ "Could not properly stringify data", .err });
                r.sendError(e, null, 505);
                return;
            };
            r.sendJson(string.items) catch |e| {
                log(@src(), .{ "Could not respond to request", .err });
                r.sendError(e, null, 505);
                return;
            };
        } else if (std.mem.eql(u8, args.task, "create")) {
            var response = creation_response{ .success = true };
            if (r.body) |body| {
                log(@src(), .{ body, .info });
                const parsed = std.json.parseFromSlice(creation_song_request, alloc.?, body, .{}) catch {
                    log(@src(), .{ "Could not create json. Please check valid json passed", .err });
                    log(@src(), .{ body, .info });
                    response.success = false;
                    var response_list = std.ArrayList(u8).init(alloc.?);
                    _ = std.json.stringify(response, .{}, response_list.writer()) catch |e| {
                        log(@src(), .{ "Could not create response json", .err });
                        r.sendError(e, null, 505);
                    };
                    r.sendJson(response_list.toOwnedSlice() catch "") catch |e| {
                        log(@src(), .{ "Could not respond to request", .err });
                        r.sendError(e, null, 505);
                    };
                    return;
                };

                log(@src(), .{ "Parsed data name:", parsed.value.name, .debug });

                db.create_song(parsed.value) catch {
                    log(@src(), .{ "could not add to database.", .err });
                    response.success = false;
                    var response_list = std.ArrayList(u8).init(alloc.?);
                    _ = std.json.stringify(response, .{}, response_list.writer()) catch |e| {
                        log(@src(), .{ "Could not create response json", .err });
                        r.sendError(e, null, 505);
                    };
                    r.sendJson(response_list.toOwnedSlice() catch "") catch |e| {
                        log(@src(), .{ "Could not respond to request", .err });
                        r.sendError(e, null, 505);
                    };
                    return;
                };

                var response_list = std.ArrayList(u8).init(alloc.?);
                _ = std.json.stringify(response, .{}, response_list.writer()) catch |e| {
                    log(@src(), .{ "Could not create response json", .err });
                    r.sendError(e, null, 505);
                };

                r.sendJson(response_list.toOwnedSlice() catch "") catch |e| {
                    log(@src(), .{ "Could not respond to request", .err });
                    r.sendError(e, null, 505);
                };
            }
        }
    }
    fn handle_beat_request(r: zap.Request, args: struct { task: []const u8 }) void {
        // play
        if (!std.mem.eql(u8, args.task, "play")) {
            r.sendBody("Please hit api/beat/play instead of invalid endpoint") catch |e| {
                log(@src(), .{ "Could not respond to request", .fatal });
                r.sendError(e, null, 505);
            };
        }

        if (r.body) |body| {
            const t: std.json.Parsed(tree) = std.json.parseFromSlice(tree, alloc.?, body, .{}) catch |e| {
                log(@src(), .{ "Could not parse json, invalid json", .err });
                r.sendError(e, null, 505);
                return;
            };

            db.create_tree(t.value) catch |e| {
                log(@src(), .{ "Could not create tree", .err });
                r.sendError(e, null, 505);
                return;
            };
        } else {
            r.sendBody("Please send json") catch |e| {
                log(@src(), .{ "No json parsed", .err });
                r.sendError(e, null, 505);
            };
        }
    }
    fn handle_config_request(r: zap.Request) void {
        // none
        r.sendBody("Config endpoint") catch |e| {
            log(@src(), .{ "Could not respond to request", .fatal });
            r.sendError(e, null, 505);
        };
    }
};
