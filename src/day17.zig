const std = @import("std");
const input = @embedFile("data/input17");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const part1 = p1: {
        var s = prepare(allocator, input);
        defer s.deinit();

        boot(&s, .d3);

        break :p1 s.active_cubes.count();
    };
    print("[Part1] Active cubes 3D: {}", .{part1});

    const part2 = p2: {
        var s = prepare(allocator, input);
        defer s.deinit();

        boot(&s, .d4);

        break :p2 s.active_cubes.count();
    };
    print("[Part2] Active cubes 4D: {}", .{part2});
}

const Pos = struct { x: i32, y: i32, z: i32, w: i32 };
const State = struct {
    const Self = @This();
    const CubeSet = std.AutoHashMap(Pos, void);

    active_cubes: CubeSet,
    next_active_cubes: CubeSet,
    bounds_min: Pos = .{ .x = -1, .y = -1, .z = -1, .w = -1 },
    bounds_max: Pos = .{ .x =  1, .y =  1, .z =  1, .w =  1 },

    pub fn init(allocator: *std.mem.Allocator) State {
        return .{
            .active_cubes = CubeSet.init(allocator),
            .next_active_cubes = CubeSet.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.active_cubes.deinit();
        self.next_active_cubes.deinit();
    }

    pub fn activate(self: *Self, pos: Pos) void {
        self.next_active_cubes.put(pos, {}) catch @panic("put failed");

        self.bounds_min.x = std.math.min(self.bounds_min.x, pos.x - 1);
        self.bounds_min.y = std.math.min(self.bounds_min.y, pos.y - 1);
        self.bounds_min.z = std.math.min(self.bounds_min.z, pos.z - 1);
        self.bounds_min.w = std.math.min(self.bounds_min.w, pos.w - 1);
        self.bounds_max.x = std.math.max(self.bounds_max.x, pos.x + 1);
        self.bounds_max.y = std.math.max(self.bounds_max.y, pos.y + 1);
        self.bounds_max.z = std.math.max(self.bounds_max.z, pos.z + 1);
        self.bounds_max.w = std.math.max(self.bounds_max.w, pos.w + 1);
    }

    pub fn deactivate(self: *Self, pos: Pos) void {
        _ = self.next_active_cubes.remove(pos);
    }

    pub fn applyChanges(self: *Self) void {
        self.active_cubes.deinit();
        self.active_cubes = self.next_active_cubes.clone() catch @panic("clone failed");
    }

    pub fn isActive(self: Self, pos: Pos) bool {
        return self.active_cubes.contains(pos);
    }
};

fn prepare(allocator: *std.mem.Allocator, input_str: []const u8) State {
    var s = State.init(allocator);

    var reader = lines(input_str);
    var pos: Pos = .{ .x = 0, .y = 0, .z = 0, .w = 0 };
    while (reader.next()) |line| : (pos.y += 1){
        for (line) |c, i| {
            pos.x = @intCast(i32, i);
            if (c == '#') {
                s.activate(pos);
            }
        }
    }

    s.applyChanges();
    return s;
}

fn boot(state: *State, comptime dim: Dim) void {
    comptime var i: usize = 0;
    inline while (i < 6) : (i += 1) {
        step(state, dim);
    }
}

const Dim = enum { d3, d4 };

fn step(state: *State, comptime dim: Dim) void {
    const min = state.bounds_min;
    const max = state.bounds_max;

    switch (dim) {
        .d3 => {
            var pos = Pos{ .x = min.x, .y = min.y, .z = min.z, .w = 0 };
            step3D(state, &pos, min, max, .d3);
        },
        .d4 => {
            var pos = min;
            step4D(state, &pos, min, max);
        },
    }
    state.applyChanges();
}

fn step4D(state: *State, pos: *Pos, min: Pos, max: Pos) void {
    pos.w = min.w;
    while (pos.w <= max.w) : (pos.w += 1) {
        step3D(state, pos, min, max, .d4);
    }
}

fn step3D(state: *State, pos: *Pos, min: Pos, max: Pos, comptime dim: Dim) void {
    pos.z = min.z;
    while (pos.z <= max.z) : (pos.z += 1) {
        pos.y = min.y;
        while (pos.y <= max.y) : (pos.y += 1) {
            pos.x = min.x;
            while (pos.x <= max.x) : (pos.x += 1) {
                const active_neighbours = countActiveNeighbours(state, pos.*, dim);
                if (state.isActive(pos.*)) {
                    if (active_neighbours != 2 and active_neighbours != 3) {
                        state.deactivate(pos.*);
                    }
                } else {
                    if (active_neighbours == 3) {
                        state.activate(pos.*);
                    }
                }
            }
        }
    }
}

fn countActiveNeighbours(state: *const State, pos: Pos, comptime dim: Dim) usize {
    var count: usize = 0;
    switch (dim) {
        .d3 => {
            const initial_offset = Pos{ .x = -1, .y = -1, .z = -1, .w = 0 };
            countActiveNeighbours3D(state, pos, initial_offset, &count);
        },
        .d4 => countActiveNeighbours4D(state, pos, &count),
    }
    return count;
}

fn countActiveNeighbours4D(state: *const State, pos: Pos, count: *usize) void {
    var offset = Pos{ .x = -1, .y = -1, .z = -1, .w = -1 };
    while (offset.w <= 1) : (offset.w += 1) {
        countActiveNeighbours3D(state, pos, offset, count);
    }
}

fn countActiveNeighbours3D(state: *const State, pos: Pos, neighbour_offset: Pos, count: *usize) void {
    var offset = neighbour_offset;
    offset.z = -1;
    while (offset.z <= 1) : (offset.z += 1) {
        offset.y = -1;
        while (offset.y <= 1) : (offset.y += 1) {
            offset.x = -1;
            while (offset.x <= 1) : (offset.x += 1) {

                if (offset.x != 0 or offset.y != 0 or offset.z != 0 or offset.w != 0) {
                    const neighbour_pos = Pos{
                        .x = pos.x + offset.x,
                        .y = pos.y + offset.y,
                        .z = pos.z + offset.z,
                        .w = pos.w + offset.w,
                    };

                    count.* += @boolToInt(state.isActive(neighbour_pos));
                }
            }
        }
    }
}

const expectEqual = std.testing.expectEqual;
test "boot 3D" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    var s = prepare(allocator, test_input);
    defer s.deinit();

    boot(&s, .d3);
    expectEqual(@as(usize, 112), s.active_cubes.count());
}
test "boot 4D" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    var s = prepare(allocator, test_input);
    defer s.deinit();

    boot(&s, .d4);
    expectEqual(@as(usize, 848), s.active_cubes.count());
}
const test_input =
    \\.#.
    \\..#
    \\###
;
