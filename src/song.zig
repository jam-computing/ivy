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
    alloc: *const std.mem.Allocator,
    frames: [][]rgb,

    pub fn init(a: *const std.mem.Allocator, song_len: usize, frame_len: usize) !song {
        var s = song{
            .alloc = a,
            .frames = &[_][]rgb{},
        };

        s.frames = try a.alloc([]rgb, song_len);

        for (s.frames) |*frame| {
            frame.* = try a.alloc(rgb, frame_len);
        }

        return s;
    }

    pub fn deinit(self: *song) void {
        for (self.frames) |frame| {
            self.alloc.free(frame);
        }
        self.alloc.free(self.frames);
    }
};
