const std = @import("std");
const input = @embedFile("data/input09");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const values = try parse(allocator, input);
    const part1 = try firstInvalidNumber(25, values);
    const part2 = try findWeakness(25, values, part1);

    print("[Part1] First invalid number: {}", .{part1});
    print("[Part2] Weakness: {}", .{part2});
}

fn parse(allocator: *std.mem.Allocator, inputStr: []const u8) ![]usize {
    var values = std.ArrayList(usize).init(allocator);
    errdefer values.deinit();

    var reader = uintLines(usize, inputStr);
    while (try reader.next()) |value| {
        try values.append(value);
    }

    return values.toOwnedSlice();
}

fn firstInvalidNumber(comptime preambleSize: usize, values: []usize) !usize {
    var preamble = Preamble(preambleSize){};
    for (values) |value| {
        if (preamble.isFull() and !preamble.isSumOfTwoNumbers(value)) {
            return value;
        }

        preamble.push(value);
    }

    return error.NoInvalidNumber;
}

fn findWeakness(comptime preambleSize: usize, values: []usize, invalidNumber: usize) !usize {
    var range_start: usize = 0;
    var range_end: usize = 0;
    var sum: usize = 0;
    while (range_end < values.len) : (range_end += 1) {
        sum += values[range_end];

        if (sum == invalidNumber) {
            var min: usize = std.math.maxInt(usize);
            var max: usize = 0;
            for (values[range_start..range_end+1]) |v| {
                min = std.math.min(min, v);
                max = std.math.max(max, v);
            }
            return min + max;

        } else if (sum > invalidNumber) {
            range_start += 1;
            range_end = range_start + 1;
            sum = values[range_start] + values[range_end];
        }
    }

    return error.NoWeakness;
}

fn Preamble(comptime size: usize) type {
    return struct {
        const Self = @This();

        values: [size]usize = std.mem.zeroes([size]usize),
        insert_pos: usize = 0,
        count: usize = 0,

        pub fn push(self: *Self, val: usize) void {
            self.values[self.insert_pos] = val;
            self.insert_pos = (self.insert_pos + 1) % size;
            self.count = std.math.min(size, self.count + 1);
        }

        pub fn isFull(self: Self) bool {
            return self.count == size;
        }

        pub fn isSumOfTwoNumbers(self: Self, value: usize) bool {
            for (self.values) |a, i| {
                for (self.values[(i + 1)..]) |b| {
                    if ((a + b) == value) {
                        return true;
                    }
                }
            }

            return false;
        }
    };
}

const expectEqual = std.testing.expectEqual;
const testInput = 
        \\35
        \\20
        \\15
        \\25
        \\47
        \\40
        \\62
        \\55
        \\65
        \\95
        \\102
        \\117
        \\150
        \\182
        \\127
        \\219
        \\299
        \\277
        \\309
        \\576
    ;
test "firstInvalidNumber" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(usize, 127), try firstInvalidNumber(5, try parse(allocator, testInput)));
}

test "findWeakness" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;
    
    expectEqual(@as(usize, 62), try findWeakness(5, try parse(allocator, testInput), 127));
}