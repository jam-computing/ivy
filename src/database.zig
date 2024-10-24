const std = @import("std");
const log = @import("stardust").sdlog;

const song = @import("song.zig").song;
const tree = @import("tree.zig").tree;

const c = @cImport({
    @cInclude("mysql/mysql.h");
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
};
