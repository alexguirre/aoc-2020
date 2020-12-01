const std = @import("std");
const Allocator = std.mem.Allocator;
const input = @embedFile("data/input01");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    var values = std.ArrayList(u64).init(allocator);
    defer values.deinit();

    var reader = UIntLineIterator(u64).init(input);
    while (try reader.next()) |val| {
        try values.append(val);
    }

    part1(values);

    part2(values);
}

const target_sum = 2020;

fn part1(values: std.ArrayList(u64)) void {
    var i: usize = 0;
    while (i < values.items.len - 1) : (i += 1) {
        var k: usize = i + 1;
        while (k < values.items.len) : (k += 1) {
            const a = values.items[i];
            const b = values.items[k];

            if ((a + b) == target_sum) {
                const result = a * b;
                print("[Part1] Result: {} * {} = {}", .{a, b, result});
                return;
            }
        }
    }

    print("[Part1] Values not found", .{});
}

fn part2(values: std.ArrayList(u64)) void {
    var i: usize = 0;
    while (i < values.items.len - 2) : (i += 1) {
        var k: usize = i + 1;
        while (k < values.items.len - 1) : (k += 1) {
            var n: usize = k + 1;
            while (n < values.items.len) : (n += 1) {
                const a = values.items[i];
                const b = values.items[k];
                const c = values.items[n];

                if ((a + b + c) == target_sum) {
                    const result = a * b * c;
                    print("[Part2] Result: {} * {} * {} = {}", .{a, b, c, result});
                    return;
                }
            }
        }
    }

    print("[Part2] Values not found", .{});
}