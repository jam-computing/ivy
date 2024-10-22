const std = @import("std");

pub const rgb = struct {
    red: u8,
    green: u8,
    blue: u8,

    pub fn atoc(str: []const u8) !rgb {
        const red_str = str[0..1];
        const col = try std.fmt.parseInt(u32, str, 16);

        std.debug.print("col: {}", .{col});

        return rgb{
            .red = 0,
            .green = 0,
            .blue = 0,
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
