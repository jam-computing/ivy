const std = @import("std");

const c = @cImport({
    @cInclude("time.h");
});

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var alloc: std.mem.Allocator = undefined;

pub var GLOBAL_LOG_LEVEL: log_level = .debug;

pub fn setup_log(level: log_level) !void {
    alloc = gpa.allocator();
    GLOBAL_LOG_LEVEL = level;
}

const RESET_ANSI: []const u8 = "\x1b[0m";

pub const log_level = enum(u8) {
    info = 0,
    debug = 1,
    err = 2,
    fatal = 3,

    pub fn to_string(self: *const log_level) []const u8 {
        return switch (self.*) {
            .info => "info",
            .debug => "debug",
            .err => "err",
            .fatal => "fatal",
        };
    }

    pub fn colour(self: *const log_level) []const u8 {
        return switch (self.*) {
            .info => "\x1b[94m",
            .debug => "\x1b[38;5;91m",
            .err => "\x1b[96m",
            .fatal => "\x1b[38;5;1m",
        };
    }
};

pub fn log(source: std.builtin.SourceLocation, args: anytype) void {
    var string = std.ArrayList(u8).init(alloc);
    defer string.deinit();

    const args_type = @TypeOf(args);

    var level: log_level = .debug;

    inline for (@typeInfo(args_type).Struct.fields) |field| {
        const field_value = @field(args, field.name);
        const field_type = @TypeOf(field_value);
        if (isZigString(field_type)) {
            string.appendSlice(field_value) catch {};
            string.appendSlice(" ") catch {};
        } else if (isZigInt(field_type)) {
            var buf: [20]u8 = undefined;
            _ = std.fmt.bufPrint(&buf, "{}", .{field_value}) catch "";
            string.appendSlice(&buf) catch {};
            string.appendSlice(" ") catch {};
        } else if (field_type == @TypeOf(std.builtin.SourceLocation)) {
            source = field_value;
        } else if (field_type == log_level) {
            level = field_value;
        } else {
            level = switch (field_value) {
                .info => .info,
                .debug => .debug,
                .err => .err,
                .fatal => .fatal,
                else => {},
            };
        }
    }

    const final_string = string.toOwnedSlice() catch "";

    if (@intFromEnum(level) >= @intFromEnum(GLOBAL_LOG_LEVEL)) {
        std.debug.print("\x1b[38;5;13m{s}\x1b[38;5;255m:\x1b[33m{s}\x1b[38;5;255m:\x1b[38;5;63m{}\x1b[38;5;255m \x1b[38;5;255m:: {s}\x1b[3m{s}\x1b[38;5;255m\x1b[0m :: {s}\n", .{
            source.file, source.fn_name, source.line, level.colour(), level.to_string(), final_string,
        });
    }
}

pub inline fn isZigInt(comptime T: type) bool {
    return comptime blk: {
        const info = @typeInfo(T);
        if (info == .Int or info == .Float) {
            break :blk true;
        }
        break :blk false;
    };
}

pub inline fn isZigString(comptime T: type) bool {
    return comptime blk: {
        // Only pointer types can be strings, no optionals
        const info = @typeInfo(T);
        if (info != .Pointer) break :blk false;

        const ptr = &info.Pointer;
        if (ptr.is_volatile or ptr.is_allowzero) break :blk false;

        if (ptr.size == .Slice) {
            break :blk ptr.child == u8;
        }

        if (ptr.size == .One) {
            const child = @typeInfo(ptr.child);
            if (child == .Array) {
                const arr = &child.Array;
                break :blk arr.child == u8;
            }
        }

        break :blk false;
    };
}
