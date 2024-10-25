const std = @import("std");
const log = @import("stardust").sdlog;

const song = @import("song.zig").song;
const rgb = @import("song.zig").rgb;
const tree = @import("tree.zig").tree;

const c = @cImport({
    @cInclude("mysql/mysql.h");
    @cInclude("stdlib.h");
    @cInclude("stdio.h");
});

var conn: ?*c.MYSQL = undefined;
var allocator: ?std.mem.Allocator = undefined;

pub const database = struct {
    pub fn init(alloc: std.mem.Allocator) void {
        conn = c.mysql_init(0);
        if (conn == null) {
            log(@src(), .{"Mariadb connection could not be established"});
            return;
        }

        allocator = alloc;

        const ip_addr = "localhost";
        const password = "password";

        if (c.mysql_real_connect(
            conn.?,
            ip_addr,
            "beech",
            password,
            "beech",
            3306,
            null,
            0,
        ) == null) {
            log(@src(), .{ "Could not connect to database", .fatal });
            std.os.linux.exit(1);
            c.mysql_close(conn.?);
            return;
        }
    }

    pub fn close() void {
        c.mysql_close(conn.?);
    }

    pub fn get_song(id: i32) !?song {
        if (conn == null) {
            log(@src(), .{ "Attempting to query on a null connection", .err });
            return null;
        }

        const query: [*c]u8 = @ptrCast(c.malloc(100));

        _ = c.sprintf(query, "select * from song where id = %d", id);

        std.debug.print("{s}\n", .{query});

        _ = c.mysql_query(conn.?, query);

        const res: *c.MYSQL_RES = c.mysql_store_result(conn.?);
        const row: c.MYSQL_ROW = c.mysql_fetch_row(res);
        if (row == null) {
            log(@src(), .{ "could not find result", .info });
            return null;
        }

        const beats = std.json.parseFromSlice([][][]const u8, allocator.?, std.mem.span(row[4]), .{}) catch {
            log(@src(), .{ "Could not parse beats from json", .err });
            return null;
        };

        const s = song{
            .id = std.fmt.parseInt(i32, std.mem.span(row[0]), 10) catch -1,
            .name = std.mem.span(row[1]),
            .author = std.mem.span(row[2]),
            .beat_count = std.fmt.parseInt(i32, std.mem.span(row[3]), 10) catch -1,
            .beats = beats.value,
        };

        return s;
    }

    pub fn get_all_songs() !?[]song {
        if (conn == null) {
            log(@src(), .{ "Attempting to query on a null connection", .err });
            return null;
        }
        _ = c.mysql_query(conn.?, "select * from song");
        const res: *c.MYSQL_RES = c.mysql_store_result(conn.?);

        var list = std.ArrayList(song).init(allocator.?);

        var row: c.MYSQL_ROW = c.mysql_fetch_row(res);

        while (row != null) {
            const beats = std.json.parseFromSlice([][][]const u8, allocator.?, std.mem.span(row[4]), .{}) catch {
                log(@src(), .{ "Could not parse beats from json", .err });
                return null;
            };
            const s = song{
                .id = std.fmt.parseInt(i32, std.mem.span(row[0]), 10) catch -1,
                .name = std.mem.span(row[1]),
                .author = std.mem.span(row[2]),
                .beat_count = std.fmt.parseInt(i32, std.mem.span(row[3]), 10) catch -1,
                .beats = beats.value,
            };

            try list.append(s);
            row = c.mysql_fetch_row(res);
        }
        return try list.toOwnedSlice();
    }

    const song_meta = struct { id: []const u8, name: []const u8, author: []const u8 };

    pub fn get_all_songs_names() !?[]song_meta {
        if (conn == null) {
            log(@src(), .{ "Attempting to query on a null connection", .err });
            return null;
        }

        _ = c.mysql_query(conn.?, "select id, name, author from song");
        const res: *c.MYSQL_RES = c.mysql_store_result(conn.?);

        var list = std.ArrayList(song_meta).init(allocator.?);
        var row: c.MYSQL_ROW = c.mysql_fetch_row(res);
        while (row != null) {
            const s = song_meta{
                .id = std.mem.span(row[0]),
                .name = std.mem.span(row[1]),
                .author = std.mem.span(row[2]),
            };
            try list.append(s);
            row = c.mysql_fetch_row(res);
        }
        return try list.toOwnedSlice();
    }

    pub fn create_tree(t: tree) !void {
        if (conn == null) {
            log(@src(), .{ "Attempting to query on a null connection", .err });
            return;
        }

        const query: [*c]u8 = @ptrCast(c.malloc(100));

        _ = c.sprintf(query, "insert into tree(name, points) values(%s, %s))", t.name.ptr, t.points.ptr);
        if (c.mysql_query(conn.?, query) != 0) {
            log(@src(), .{ "Could not insert tree into db", .err });
        }
        log(@src(), .{ "Succesfully created tree", .info });
    }

    pub fn get_all_trees() !?[]tree {
        if (conn == null) {
            log(@src(), .{ "Attempting to query on a null connection", .err });
            return null;
        }
        _ = c.mysql_query(conn.?, "select * from tree");
        const res: *c.MYSQL_RES = c.mysql_store_result(conn.?);

        var list = std.ArrayList(tree).init(allocator.?);

        var row: c.MYSQL_ROW = c.mysql_fetch_row(res);
        while (row != null) {
            const s = tree{
                .id = std.fmt.parseInt(i32, std.mem.span(row[0]), 10) catch -1,
                .name = std.mem.span(row[1]),
                .points = std.mem.span(row[2]),
            };
            try list.append(s);
            row = c.mysql_fetch_row(res);
        }
        return try list.toOwnedSlice();
    }

    const tree_meta = struct { id: []const u8, name: []const u8 };

    pub fn get_all_trees_names() !?[]tree_meta {
        if (conn == null) {
            log(@src(), .{ "Attempting to query on a null connection", .err });
            return null;
        }
        _ = c.mysql_query(conn.?, "select id, name from tree");
        const res: *c.MYSQL_RES = c.mysql_store_result(conn.?);

        var list = std.ArrayList(tree_meta).init(allocator.?);

        var row: c.MYSQL_ROW = c.mysql_fetch_row(res);
        while (row != null) {
            const s = tree_meta{
                .id = std.mem.span(row[0]),
                .name = std.mem.span(row[1]),
            };
            try list.append(s);
            row = c.mysql_fetch_row(res);
        }
        return try list.toOwnedSlice();
    }
};
