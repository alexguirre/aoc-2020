const std = @import("std");
const input = [_]i32{ 0, 12, 6, 13, 20, 1, 17 };
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const part1 = findNumberAtTurn(allocator, &input, 2020);
    const part2 = findNumberAtTurn(allocator, &input, 30000000);

    print("[Part1] 2020th:     {}", .{part1});
    print("[Part2] 30000000th: {}", .{part2});
}

fn findNumberAtTurn(allocator: *std.mem.Allocator, numbers: []const i32, comptime target_turn: i32) i32 {
    var spoken = NumberMap.init(allocator);
    defer spoken.deinit();

    var turn: i32 = 1;
    var lastNumber: i32 = undefined;
    for (numbers) |n| {
        insertNumber(&spoken, n, turn);
        turn += 1;
        lastNumber = n;
    }

    while (true) : (turn += 1) {
        if (spoken.get(lastNumber)) |numInfo| {
            const n = if (numInfo.prevTurn == 0) 0 else (std.math.absInt(numInfo.turn - numInfo.prevTurn) catch @panic("absInt failed"));
            insertNumber(&spoken, n, turn);
            lastNumber = n;

            if (turn == target_turn) {
                return n;
            }
        } else unreachable;
    }
}

const NumberInfo = struct { turn: i32, prevTurn: i32 };
const NumberMap = std.AutoHashMap(i32, NumberInfo);

fn insertNumber(map: *NumberMap, number: i32, turn: i32) void {
    if (map.get(number)) |info| {
        map.put(number, .{ .turn = turn, .prevTurn = info.turn }) catch @panic("put failed");
    } else {
        map.put(number, .{ .turn = turn, .prevTurn = 0 }) catch @panic("put failed");
    }
}

const expectEqual = std.testing.expectEqual;
test "findNumberAtTurn2020" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(i32, 436),  findNumberAtTurn(allocator, &[_]i32{ 0, 3, 6 }, 2020));
    expectEqual(@as(i32, 1),    findNumberAtTurn(allocator, &[_]i32{ 1, 3, 2 }, 2020));
    expectEqual(@as(i32, 10),   findNumberAtTurn(allocator, &[_]i32{ 2, 1, 3 }, 2020));
    expectEqual(@as(i32, 27),   findNumberAtTurn(allocator, &[_]i32{ 1, 2, 3 }, 2020));
    expectEqual(@as(i32, 78),   findNumberAtTurn(allocator, &[_]i32{ 2, 3, 1 }, 2020));
    expectEqual(@as(i32, 438),  findNumberAtTurn(allocator, &[_]i32{ 3, 2, 1 }, 2020));
    expectEqual(@as(i32, 1836), findNumberAtTurn(allocator, &[_]i32{ 3, 1, 2 }, 2020));
}
test "findNumberAtTurn30000000" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(i32, 175594),  findNumberAtTurn(allocator, &[_]i32{ 0, 3, 6 }, 30000000));
    expectEqual(@as(i32, 2578),    findNumberAtTurn(allocator, &[_]i32{ 1, 3, 2 }, 30000000));
    expectEqual(@as(i32, 3544142), findNumberAtTurn(allocator, &[_]i32{ 2, 1, 3 }, 30000000));
    expectEqual(@as(i32, 261214),  findNumberAtTurn(allocator, &[_]i32{ 1, 2, 3 }, 30000000));
    expectEqual(@as(i32, 6895259), findNumberAtTurn(allocator, &[_]i32{ 2, 3, 1 }, 30000000));
    expectEqual(@as(i32, 18),      findNumberAtTurn(allocator, &[_]i32{ 3, 2, 1 }, 30000000));
    expectEqual(@as(i32, 362),     findNumberAtTurn(allocator, &[_]i32{ 3, 1, 2 }, 30000000));
}