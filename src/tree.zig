pub const tree = struct {
    id: i32,
    name: []const u8,
    points: []struct {
        x: i32,
        y: i32,
        z: i32,
    },
};
