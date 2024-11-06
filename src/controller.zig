const std = @import("std");
const song = @import("song.zig").song;
const log = @import("stardust").sdlog;

const c = @cImport({
    @cInclude("rpi_ws281x/ws2811.h");
    @cInclude("signal.h");
});

pub const controller_init_error = error{
    COULD_NOT_INIT,
    COULD_NOT_RENDER,
};

pub const controller_render_error = error{
    COULD_NOT_RENDER,
};

const play_type = union(enum) {
    song: [][][]const u8,
    beat: [][]const u8,
    none,
};

const state = struct {
    play_type: play_type,
    current_duration: u32,
};

pub const controller_state = struct {
    state: state,
    mutex: std.Thread.Mutex,

    pub fn init(allocator: *std.mem.Allocator) !*controller_state {
        return allocator.create(controller_state) catch |e| {
            return e;
        };
    }

    pub fn deinit(self: *controller_state, allocator: *std.mem.Allocator) void {
        allocator.destroy(self);
    }

    // Thread-safe getter function
    pub fn getPlayType(self: *controller_state) play_type {
        self.mutex.lock();
        const result = self.state.play_type;
        self.mutex.unlock();
        return result;
    }

    // Thread-safe setter function
    pub fn setPlayType(self: *controller_state, newPlayType: play_type) void {
        self.mutex.lock();
        self.state.play_type = newPlayType;
        self.mutex.unlock();
    }

    pub fn getAlive(self: *controller_state) bool {
        self.mutex.lock();
        const result = self.state.alive;
        self.mutex.unlock();
        return result;
    }

    pub fn setAlive(self: *controller_state, live: bool) void {
        self.mutex.lock();
        self.state.alive = live;
        self.mutex.unlock();
    }
};

pub var GLOBAL_CONTROLLER_STATE: *controller_state = undefined;

const LED_COUNT = 50;

var WS281X: c.ws2811_t = undefined;

pub fn init(alloc: *std.mem.Allocator) !void {
    GLOBAL_CONTROLLER_STATE = try controller_state.init(alloc);

    WS281X.freq = c.WS2811_TARGET_FREQ;
    WS281X.dmanum = 10;
    WS281X.channel[0].gpionum = 18;
    WS281X.channel[0].count = 50;
    WS281X.channel[0].invert = 0;
    WS281X.channel[0].brightness = 255;
    WS281X.channel[0].strip_type = c.WS2811_STRIP_RGB;

    if (c.ws2811_init(&WS281X) != c.WS2811_SUCCESS) {
        std.debug.print("Error initialising ws2811\n", .{});
        return controller_init_error.COULD_NOT_INIT;
    }

    WS281X.channel[0].leds[0] = 0xFF0000;
    WS281X.channel[0].leds[1] = 0x00FF00;
    WS281X.channel[0].leds[2] = 0x0000FF;

    if (c.ws2811_render(&WS281X) != c.WS2811_SUCCESS) {
        std.debug.print("Could not render", .{});
        return controller_init_error.COULD_NOT_RENDER;
    }
}

pub fn start_loop(pid: i32) void {
    while (true) {
        log(@src(), .{ "One Second", .debug });
        std.time.sleep(1 * std.time.ns_per_s);
        if (c.kill(pid, 0) == 1) {
            log(@src(), .{ "Main thread stopped, stopping", .debug });
            return;
        }
    }
}

fn play(_: *const song) void {
    // loop through and play frames
}

fn play_beat(_: *const [][]const u8) void {
    _ = WS281X.channel[0];
}
