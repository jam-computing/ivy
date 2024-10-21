const std = @import("std");

pub const rgb = struct {
    red: u8,
    green: u8,
    blue: u8,
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
