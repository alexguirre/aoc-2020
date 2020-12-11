const std = @import("std");
const input = @embedFile("data/input11");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const part1 = try findFinalOccupied(allocator, input, .adjacent);
    const part2 = try findFinalOccupied(allocator, input, .first_visible);

    print("[Part1] Number of occupied seats: {}", .{part1});
    print("[Part2] Number of occupied seats: {}", .{part2});
}

const floor = '.';
const empty = 'L';
const occupied = '#';

const State = struct {
    width: usize,
    height: usize,
    grids: [2][]u8,
    curr_grid: usize,
    next_grid: usize,

    pub fn init(allocator: *std.mem.Allocator, grid: []const u8) !State {
        return State {
            .width = std.mem.indexOf(u8, grid, "\n") orelse return error.InvalidGrid,
            .height = std.mem.count(u8, grid, "\n"),
            .grids = [_][]u8 {
                try std.mem.dupe(allocator, u8, grid),
                try std.mem.dupe(allocator, u8, grid),
            },
            .curr_grid = 0,
            .next_grid = 1,
        };
    }

    pub inline fn getCurrGrid(state: State) []const u8 {
        return state.grids[state.curr_grid];
    }

    pub inline fn index(state: State, x: usize, y: usize) usize {
        return y * (state.width + 1) + x;
    }

    pub inline fn get(state: State, x: usize, y: usize) u8 {
        return state.getCurrGrid()[state.index(x, y)];
    }

    pub inline fn setNext(state: *State, x: usize, y: usize, s: u8) void {
        state.grids[state.next_grid][state.index(x, y)] = s;
    }

    pub inline fn switchGrids(state: *State) void {
        state.curr_grid = (state.curr_grid + 1) & 1;
        state.next_grid = (state.next_grid + 1) & 1;
    }
};

fn step(state: *State, comptime method: CountMethod) void {
    var x: usize = 0;
    while (x < state.width) : (x += 1) {
        var y: usize = 0;
        while (y < state.height) : (y += 1) {
            const s = state.get(x, y);

            if (s != floor) {
                const occupied_limit = if (method == .first_visible) 5 else 4;
                const num_occupied = countOccupiedNeighbours(state.*, x, y, method);
                const next: u8 = switch (s) {
                    empty => @as(u8, if (num_occupied == 0) occupied else empty),
                    occupied => @as(u8, if (num_occupied >= occupied_limit) empty else occupied),
                    else => unreachable,
                };
                state.setNext(x, y, next);
            }
        }
    }

    state.switchGrids();
}

const CountMethod = enum { adjacent, first_visible };

fn countOccupiedNeighbours(state: State, x: usize, y: usize, comptime method: CountMethod) usize {
    const offsets_x = [_]isize { -1, 0, 1, -1, 1, -1, 0, 1 };
    const offsets_y = [_]isize { -1, -1, -1, 0, 0, 1, 1, 1 };

    var count: usize = 0;
    comptime var i: usize = 0;
    inline while (i < offsets_x.len) : (i += 1) {
        var neighbour_x = @intCast(isize, x);
        var neighbour_y = @intCast(isize, y);
        inner: while (true) {
            neighbour_x += offsets_x[i];
            neighbour_y += offsets_y[i];

            const in_bounds = neighbour_x >= 0 and neighbour_x < state.width and neighbour_y >= 0 and neighbour_y < state.height;
            const neighbour = if (in_bounds) state.get(@intCast(usize, neighbour_x), @intCast(usize, neighbour_y)) else floor;
            switch (method) {
                .adjacent => {
                    count += @boolToInt(neighbour == occupied);
                    break :inner;
                },
                .first_visible => {
                    if (!in_bounds) {
                        break :inner;
                    }

                    if (neighbour != floor) {
                        count += @boolToInt(neighbour == occupied);
                        break :inner;
                    }
                }
            }
        }
    }

    return count;
}

fn findFinalOccupied(allocator: *std.mem.Allocator, initial_grid: []const u8, comptime method: CountMethod) !usize {
    var state = try State.init(allocator, initial_grid);

    while (true) {
        step(&state, method);

        if (std.mem.eql(u8, state.grids[0], state.grids[1])) { // grid didn't change
            break;
        }
    }

    var num_occupied: usize = 0;
    var x: usize = 0;
    while (x < state.width) : (x += 1) {
        var y: usize = 0;
        while (y < state.height) : (y += 1) {
            const s = state.get(x, y);
            num_occupied += @boolToInt(s == occupied);
        }
    }
    return num_occupied;
}



const expectEqualStrings = std.testing.expectEqualStrings;
const expectEqual = std.testing.expectEqual;
test "step adjacent" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;


    var state = try State.init(allocator, test_grid_initial);
    expectEqualStrings(test_grid_initial, state.getCurrGrid());

    step(&state, .adjacent);
    expectEqualStrings(test_grid_step1, state.getCurrGrid());
    
    step(&state, .adjacent);
    expectEqualStrings(test_grid_step2, state.getCurrGrid());
    
    step(&state, .adjacent);
    expectEqualStrings(test_grid_step3, state.getCurrGrid());
    
    step(&state, .adjacent);
    expectEqualStrings(test_grid_step4, state.getCurrGrid());
    
    step(&state, .adjacent);
    expectEqualStrings(test_grid_step5, state.getCurrGrid());
    
    step(&state, .adjacent);
    expectEqualStrings(test_grid_step5, state.getCurrGrid());
}

test "step first visible" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;


    var state = try State.init(allocator, test_grid_initial);
    expectEqualStrings(test_grid_initial, state.getCurrGrid());

    step(&state, .first_visible);
    expectEqualStrings(test_grid_step1_first_visible, state.getCurrGrid());
    
    step(&state, .first_visible);
    expectEqualStrings(test_grid_step2_first_visible, state.getCurrGrid());
    
    step(&state, .first_visible);
    expectEqualStrings(test_grid_step3_first_visible, state.getCurrGrid());
    
    step(&state, .first_visible);
    expectEqualStrings(test_grid_step4_first_visible, state.getCurrGrid());
    
    step(&state, .first_visible);
    expectEqualStrings(test_grid_step5_first_visible, state.getCurrGrid());
    
    step(&state, .first_visible);
    expectEqualStrings(test_grid_step6_first_visible, state.getCurrGrid());
    
    step(&state, .first_visible);
    expectEqualStrings(test_grid_step6_first_visible, state.getCurrGrid());
}

test "findFinalOccupied" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(usize, 37), try findFinalOccupied(allocator, test_grid_initial, .adjacent));
    expectEqual(@as(usize, 26), try findFinalOccupied(allocator, test_grid_initial, .first_visible));
}

const test_grid_initial =
    \\L.LL.LL.LL
    \\LLLLLLL.LL
    \\L.L.L..L..
    \\LLLL.LL.LL
    \\L.LL.LL.LL
    \\L.LLLLL.LL
    \\..L.L.....
    \\LLLLLLLLLL
    \\L.LLLLLL.L
    \\L.LLLLL.LL
    \\
;
const test_grid_step1 =
    \\#.##.##.##
    \\#######.##
    \\#.#.#..#..
    \\####.##.##
    \\#.##.##.##
    \\#.#####.##
    \\..#.#.....
    \\##########
    \\#.######.#
    \\#.#####.##
    \\
;
const test_grid_step2 =
    \\#.LL.L#.##
    \\#LLLLLL.L#
    \\L.L.L..L..
    \\#LLL.LL.L#
    \\#.LL.LL.LL
    \\#.LLLL#.##
    \\..L.L.....
    \\#LLLLLLLL#
    \\#.LLLLLL.L
    \\#.#LLLL.##
    \\
;
const test_grid_step3 =
    \\#.##.L#.##
    \\#L###LL.L#
    \\L.#.#..#..
    \\#L##.##.L#
    \\#.##.LL.LL
    \\#.###L#.##
    \\..#.#.....
    \\#L######L#
    \\#.LL###L.L
    \\#.#L###.##
    \\
;
const test_grid_step4 =
    \\#.#L.L#.##
    \\#LLL#LL.L#
    \\L.L.L..#..
    \\#LLL.##.L#
    \\#.LL.LL.LL
    \\#.LL#L#.##
    \\..L.L.....
    \\#L#LLLL#L#
    \\#.LLLLLL.L
    \\#.#L#L#.##
    \\
;
const test_grid_step5 =
    \\#.#L.L#.##
    \\#LLL#LL.L#
    \\L.#.L..#..
    \\#L##.##.L#
    \\#.#L.LL.LL
    \\#.#L#L#.##
    \\..L.L.....
    \\#L#L##L#L#
    \\#.LLLLLL.L
    \\#.#L#L#.##
    \\
;


const test_grid_step1_first_visible =
    \\#.##.##.##
    \\#######.##
    \\#.#.#..#..
    \\####.##.##
    \\#.##.##.##
    \\#.#####.##
    \\..#.#.....
    \\##########
    \\#.######.#
    \\#.#####.##
    \\
;
const test_grid_step2_first_visible =
    \\#.LL.LL.L#
    \\#LLLLLL.LL
    \\L.L.L..L..
    \\LLLL.LL.LL
    \\L.LL.LL.LL
    \\L.LLLLL.LL
    \\..L.L.....
    \\LLLLLLLLL#
    \\#.LLLLLL.L
    \\#.LLLLL.L#
    \\
;
const test_grid_step3_first_visible =
    \\#.L#.##.L#
    \\#L#####.LL
    \\L.#.#..#..
    \\##L#.##.##
    \\#.##.#L.##
    \\#.#####.#L
    \\..#.#.....
    \\LLL####LL#
    \\#.L#####.L
    \\#.L####.L#
    \\
;
const test_grid_step4_first_visible =
    \\#.L#.L#.L#
    \\#LLLLLL.LL
    \\L.L.L..#..
    \\##LL.LL.L#
    \\L.LL.LL.L#
    \\#.LLLLL.LL
    \\..L.L.....
    \\LLLLLLLLL#
    \\#.LLLLL#.L
    \\#.L#LL#.L#
    \\
;
const test_grid_step5_first_visible =
    \\#.L#.L#.L#
    \\#LLLLLL.LL
    \\L.L.L..#..
    \\##L#.#L.L#
    \\L.L#.#L.L#
    \\#.L####.LL
    \\..#.#.....
    \\LLL###LLL#
    \\#.LLLLL#.L
    \\#.L#LL#.L#
    \\
;
const test_grid_step6_first_visible =
    \\#.L#.L#.L#
    \\#LLLLLL.LL
    \\L.L.L..#..
    \\##L#.#L.L#
    \\L.L#.LL.L#
    \\#.LLLL#.LL
    \\..#.L.....
    \\LLL###LLL#
    \\#.LLLLL#.L
    \\#.L#LL#.L#
    \\
;