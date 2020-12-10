const std = @import("std");
const input = @embedFile("data/input10");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const values = try parse(allocator, input);

    const part1 = findChain(values);
    const part2 = countDistinctArrangements(values);
    print("[Part1] Chain: {}", .{part1});
    print("[Part2] Distinct arrangements: {}", .{part2});
}

fn parse(allocator: *std.mem.Allocator, inputStr: []const u8) ![]u32 {
    var values = std.ArrayList(u32).init(allocator);
    errdefer values.deinit();

    try values.append(0); // outlet
    var builtIn: u32 = 0;
    var reader = uintLines(u32, inputStr);
    while (try reader.next()) |value| {
        try values.append(value);
        builtIn = std.math.max(builtIn, value);
    }

    builtIn += 3;
    try values.append(builtIn);

    std.sort.sort(u32, values.items, {}, comptime std.sort.asc(u32));
    return values.toOwnedSlice();
}

fn findChain(values: []u32) u32 {
    var countOf1: u32 = 0;
    var countOf3: u32 = 0;
    for (values[1..]) |v, i| {
        const diff = v - values[i];
        countOf1 += @boolToInt(diff == 1);
        countOf3 += @boolToInt(diff == 3);
    }

    return countOf1 * countOf3;
}

fn countDistinctArrangements(values: []u32) usize {
    var n: [3]usize = [_]usize { 1, 0, 0 };
    var ii = @intCast(isize, values.len - 2);
    while (ii >= 0) : (ii -= 1) {
        var s: usize = 0;
        const i = @intCast(usize, ii);
        var k = i + 1;
        while (k < values.len and (values[k] - values[i]) <= 3) : (k += 1) {
            s += n[k - i - 1];
        }

        n[2] = n[1];
        n[1] = n[0];
        n[0] = s;
    }

    return n[0];
}

const expectEqual = std.testing.expectEqual;
test "findChain" {
    var values1 = try parse(std.testing.allocator, testInput1);
    defer std.testing.allocator.free(values1);

    expectEqual(@as(u32, 7 * 5), findChain(values1));
    
    var values2 = try parse(std.testing.allocator, testInput2);
    defer std.testing.allocator.free(values2);

    expectEqual(@as(u32, 22 * 10), findChain(values2));
}

test "countDistinctArrangements" {
    var values1 = try parse(std.testing.allocator, testInput1);
    defer std.testing.allocator.free(values1);

    expectEqual(@as(usize, 8), countDistinctArrangements(values1));
    
    var values2 = try parse(std.testing.allocator, testInput2);
    defer std.testing.allocator.free(values2);

    expectEqual(@as(usize, 19208), countDistinctArrangements(values2));
}

const testInput1 =
    \\16
    \\10
    \\15
    \\5
    \\1
    \\11
    \\7
    \\19
    \\6
    \\12
    \\4
;

const testInput2 = 
    \\28
    \\33
    \\18
    \\42
    \\31
    \\14
    \\46
    \\20
    \\48
    \\47
    \\24
    \\23
    \\49
    \\45
    \\19
    \\38
    \\39
    \\11
    \\1
    \\32
    \\25
    \\35
    \\8
    \\17
    \\7
    \\9
    \\4
    \\2
    \\34
    \\10
    \\3
;