const std = @import("std");

const c = @cImport({
    @cInclude("time.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var alloc: std.mem.Allocator = undefined;

pub fn setup_log() !void {
    alloc = gpa.allocator();
}

pub fn debug(comptime fmt: []const u8, args: anytype) void {
    var string = std.ArrayList(u8).init(alloc);
    defer string.deinit();

    var source: std.builtin.SourceLocation = undefined;
    if(@TypeOf(args.@"0") != @TypeOf(std.builtin.SourceLocation)) {
        source = @src();
    } else {
        source = args.@"0";
    }
    inline for(args) |arg| {
        if(@TypeOf(arg) != @TypeOf(std.builtin.SourceLocation)) {
            continue;
        }
        std.debug.print("arg: {}", .{arg});
    }
    std.debug.print("\x1b[38;5;13m{s}\x1b[38;5;255m:\x1b[33m{s}\x1b[38;5;255m:\x1b[38;5;63m{}\x1b[38;5;255m \x1b[38;5;255m:: \x1b[1m\x1b[38;5;91m\x1b[3mDEBUG\x1b[38;5;255m\x1b[0m :: {s}\n", .{
        source.file, source.fn_name, source.line, fmt,
    });
}
