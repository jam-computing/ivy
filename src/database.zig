const log = @import("stardust").sdlog;
const c = @cImport({
    @cInclude("mysql/mysql.h");
});

var conn: ?*c.MYSQL = undefined;

pub const database = struct {
    pub fn init() void {
        conn = c.mysql_init(0);
        if (conn == null) {
            log(@src(), .{"Mariadb connection could not be established"});
            return;
        }

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
            c.mysql_close(conn.?);
            return;
        }
    }

    pub fn close() void {
        c.mysql_close(conn.?);
    }
};
