const std = @import("std");

pub const rgb = struct {
    red: u8,
    green: u8,
    blue: u8,
    alpha: u8,

    pub fn atoc(str: []const u8) !rgb {
        const red_str = str[0..2];
        const red = try std.fmt.parseInt(u32, red_str, 16);
        const green_str = str[2..4];
        const green = try std.fmt.parseInt(u32, green_str, 16);
        const blue_str = str[4..6];
        const blue = try std.fmt.parseInt(u32, blue_str, 16);
        const alpha_str = str[6..8];
        const alpha = try std.fmt.parseInt(u32, alpha_str, 16);

        return rgb{
            .red = @intCast(red),
            .green = @intCast(green),
            .blue = @intCast(blue),
            .alpha = @intCast(alpha),
        };
    }

    pub fn new() rgb {
        return rgb{ .red = 0, .green = 0, .blue = 0 };
    }
};

pub const song = struct {
    id: i32,
    name: []const u8,
    author: []const u8,
    beat_count: i32,
    beats: [][][]const u8,

    pub fn new() song {
        return song{
            .id = -1,
            .name = "",
            .author = "",
            .beat_count = 0,
            .beats = &[_][][]const u8{},
        };
    }

    pub fn init(a: *const std.mem.Allocator, count: usize, beat_length: usize) !song {
        var s = song.new();
        s.beats = try a.alloc([]rgb, count);

        for (s.beats) |*beat| {
            beat.* = try a.alloc(rgb, beat_length);
        }

        return s;
    }

    pub fn deinit(a: *const std.mem.Allocator, self: *song) void {
        for (self.beats) |beat| {
            a.free(beat);
        }
        a.free(self.beats);
    }
};
