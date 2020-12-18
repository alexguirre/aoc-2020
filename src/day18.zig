const std = @import("std");
const input = @embedFile("data/input18");
usingnamespace @import("util.zig");

pub fn main() !void {
    const part1 = b: {
        var sum: u64 = 0;
        var reader = lines(input);
        while (reader.next()) |line| {
            sum += eval(line);
        }
        break :b sum;
    };

    print("[Part1] Sum: {}", .{part1});
}

fn eval(expr: []const u8) u64 {
    var e = expr;
    return evalRecursive(&e);
}

fn evalRecursive(expr: *[]const u8) u64 {

    var result: u64 = 0;
    var op: ?u8 = '+';
    while (expr.len > 0) {
        const c = expr.*[0];
        const val = switch (c) {
            '0'...'9' => @intCast(u64, c - '0'),
            '(' => b: { expr.* = expr.*[1..]; break :b evalRecursive(expr); },
            ')' => return result,
            else => null,
        };

        if (val) |v| {
            if (op) |o| {
                switch (o) {
                    '+' => result += v,
                    '*' => result *= v,
                    else => unreachable,
                }
                op = null;
            }
        }

        switch (c) {
            '+', '*' => op = c,
            else => {},
        }

        expr.* = expr.*[1..];
    }

    return result;
}

const expectEqual = std.testing.expectEqual;
test "eval" {
    expectEqual(@as(u64, 26),    eval("2 * 3 + (4 * 5)"));
    expectEqual(@as(u64, 437),   eval("5 + (8 * 3 + 9 + 3 * 4 * 3)"));
    expectEqual(@as(u64, 12240), eval("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))"));
    expectEqual(@as(u64, 13632), eval("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2"));
}
