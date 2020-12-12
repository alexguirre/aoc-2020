const std = @import("std");
const input = @embedFile("data/input12");
usingnamespace @import("util.zig");

pub fn main() !void {
    const part1 = findManhattanDistance(input, .one);
    const part2 = findManhattanDistance(input, .two);

    print("[Part1] Distance: {}", .{part1});
    print("[Part2] Distance: {}", .{part2});
}

const Ship = struct {
    x: isize = 0,
    y: isize = 0,
    facing: u8 = 'E',
    waypoint_x: isize = 10,
    waypoint_y: isize = 1,
};

const Part = enum { one, two };

fn findManhattanDistance(inputStr: []const u8, comptime part: Part) usize {
    var ship: Ship = .{};

    var reader = lines(inputStr);
    while (reader.next()) |line| {
        const inst = line[0];
        const value = std.fmt.parseUnsigned(isize, line[1..], 10) catch unreachable;
        move(&ship, inst, value, part);
    }

    const x = std.math.absInt(ship.x) catch unreachable;
    const y = std.math.absInt(ship.y) catch unreachable;
    return @intCast(usize, x + y);
}

fn move(ship: *Ship, inst: u8, value: isize, comptime part: Part) void {
    switch (part) {
        .one => moveV1(ship, inst, value),
        .two => moveV2(ship, inst, value),
    }
}

fn moveV1(ship: *Ship, inst: u8, value: isize) void {
    switch (inst) {
        'N' => ship.y += value,
        'S' => ship.y -= value,
        'E' => ship.x += value,
        'W' => ship.x -= value,
        'L' => ship.facing = rotate('L', ship.facing, value),
        'R' => ship.facing = rotate('R', ship.facing, value),
        'F' => moveV1(ship, ship.facing, value),
        else => unreachable,
    }
}

fn moveV2(ship: *Ship, inst: u8, value: isize) void {
    switch (inst) {
        'N' => ship.waypoint_y += value,
        'S' => ship.waypoint_y -= value,
        'E' => ship.waypoint_x += value,
        'W' => ship.waypoint_x -= value,
        'L' => rotateWaypoint('L', &ship.waypoint_x, &ship.waypoint_y, value),
        'R' => rotateWaypoint('R', &ship.waypoint_x, &ship.waypoint_y, value),
        'F' => {
            ship.x += ship.waypoint_x * value;
            ship.y += ship.waypoint_y * value;
        },
        else => unreachable,
    }
}

fn rotate(comptime turn_dir: u8, facing: u8, degrees: isize) u8 {
    const steps = @intCast(usize, @divExact(degrees, 90)) % 4;

    const directions = [_]u8 { 'E', 'N', 'W', 'S' };
    const index = std.mem.indexOf(u8, &directions, &[_]u8 { facing }) orelse unreachable;

    const newIndex = switch (turn_dir) {
        'L' => index + steps,
        'R' => (index + directions.len) - steps,
        else => unreachable,
    } % directions.len;

    return directions[newIndex];
}

fn rotateWaypoint(comptime turn_dir: u8, x: *isize, y: *isize, degrees: isize) void {
    const num_steps = @intCast(usize, @divExact(degrees, 90)) % 4;
    const steps_to_the_left = if (turn_dir == 'L') num_steps else (4 - num_steps) % 4;

    const x_val = x.*;
    const y_val = y.*;
    switch (steps_to_the_left) {
        0 => {},
        1 => { x.* = -y_val; y.* =  x_val; },
        2 => { x.* = -x_val; y.* = -y_val; },
        3 => { x.* =  y_val; y.* = -x_val; },
        else => unreachable,
    }
}

const expectEqual = std.testing.expectEqual;
test "findManhattanDistance" {
    expectEqual(@as(usize, 25), findManhattanDistance(
        \\F10
        \\N3
        \\F7
        \\R90
        \\F11
    , .one));

    expectEqual(@as(usize, 286), findManhattanDistance(
        \\F10
        \\N3
        \\F7
        \\R90
        \\F11
    , .two));
}