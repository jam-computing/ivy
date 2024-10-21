const std = @import("std");
const song = @import("song.zig").song;

const c = @cImport({
    @cInclude("rpi_ws281x/ws2811.h");
});

pub const controller_init_error = error {
    COULD_NOT_INIT,
    COULD_NOT_RENDER,
};

const LED_COUNT = 50;

pub const controller = struct {
    ws281x: c.ws2811_t,

    pub fn init() controller_init_error!controller {
        var ledstring: c.ws2811_t = undefined;

        ledstring.freq = c.WS2811_TARGET_FREQ;
        ledstring.dmanum = 10;
        ledstring.channel[0].gpionum = 18;
        ledstring.channel[0].count = 50;
        ledstring.channel[0].invert = 0;
        ledstring.channel[0].brightness = 255;
        ledstring.channel[0].strip_type = c.WS2811_STRIP_RGB;

        if(c.ws2811_init(&ledstring) != c.WS2811_SUCCESS) {
            std.debug.print("Error initialising ws2811\n", .{});
            return controller_init_error.COULD_NOT_INIT;
        }

        ledstring.channel[0].leds[0] = 0xFF0000;
        ledstring.channel[0].leds[1] = 0x00FF00;
        ledstring.channel[0].leds[2] = 0x0000FF;

        if(c.ws2811_render(&ledstring) != c.WS2811_SUCCESS) {
            std.debug.print("Could not render", .{});
            return controller_init_error.COULD_NOT_RENDER;
        }

        return controller { .ws281x = ledstring };
    }

    pub fn play(_: *controller, _: *const song) void {

    }
};
