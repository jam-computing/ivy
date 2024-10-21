const std = @import("std");

const c = @cImport({
    @cInclude("time.h");
});

pub fn debug(str: []const u8, src: ?std.builtin.SourceLocation) void {
    const source: std.builtin.SourceLocation = src orelse @src();
    std.debug.print("\x1b[38;5;13m{s}\x1b[38;5;255m:\x1b[33m{s}\x1b[38;5;255m:\x1b[38;5;63m{}\x1b[38;5;255m \x1b[38;5;255m:: \x1b[1m\x1b[38;5;91m\x1b[3mDEBUG\x1b[38;5;255m\x1b[0m :: {s}\n", .{
        source.file, source.fn_name, source.line, str,
    });
}
