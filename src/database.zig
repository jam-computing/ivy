const log = @import("log.zig");
const c = @cImport({
    @cInclude("mysql/mysql.h");
});

pub var conn: *c.MYSQL = undefined;

pub const database = struct {
    pub fn init() void {
        conn = c.mysql_init(0);
        if(conn == c.NULL) {
            log.debug("Mariadb connection could not be established", @src());
            return;
        }
    }
};
