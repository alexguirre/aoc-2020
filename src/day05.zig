const std = @import("std");
const input = @embedFile("data/input05");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    var seats = std.ArrayList(usize).init(allocator);
    defer seats.deinit();

    var highestSeatId: usize = 0;
    var reader = lines(input);
    while (reader.next()) |line| {
        const seatId = findSeat(line);
        highestSeatId = std.math.max(highestSeatId, seatId);
        try seats.append(seatId);
    }

    std.sort.sort(usize, seats.items, {}, comptime std.sort.asc(usize));
    const mySeatId = for (seats.items[0..seats.items.len - 1]) |seat, i| {
        const nextSeat = seats.items[i + 1];
        if ((nextSeat - seat) != 1) {
            break (seat + 1);
        }
    } else unreachable;

    print("[Part1] Highest seat ID: {}", .{highestSeatId});
    print("[Part2] My seat ID: {}", .{mySeatId});
}

fn findSeat(sequence: []const u8) usize {
    if (sequence.len != 10) unreachable;

    const row = search(sequence[0..7], 'F', 'B');
    const col = search(sequence[7..10], 'L', 'R');
    return row * 8 + col;
}

fn search(sequence: []const u8, comptime lowerHalfCode: u8, comptime upperHalfCode: u8) usize {
    var val: usize = 0;
    for (sequence) |c| {
        val <<= 1;
        switch (c) {
            lowerHalfCode => {},
            upperHalfCode => val += 1,
            else => unreachable,
        }
    }

    return val;
}

const expectEqual = std.testing.expectEqual;
test "search" {
    expectEqual(@as(usize, 44), search("FBFBBFF", 'F', 'B'));
    expectEqual(@as(usize, 5), search("RLR", 'L', 'R'));
}

test "findSeat" {
    expectEqual(@as(usize, 567), findSeat("BFFFBBFRRR"));
    expectEqual(@as(usize, 119), findSeat("FFFBBBFRRR"));
    expectEqual(@as(usize, 820), findSeat("BBFFBBFRLL"));
}