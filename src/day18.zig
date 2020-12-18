const std = @import("std");
const input = @embedFile("data/input18");
usingnamespace @import("util.zig");

pub fn main() !void {
    var part1: u64 = 0;
    var part2: u64 = 0;

    var reader = lines(input);
    while (reader.next()) |line| {
        part1 += eval(line);
        part2 += try evalV2(line);
    }

    print("[Part1] Sum: {}", .{part1});
    print("[Part2] Sum: {}", .{part2});
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

fn evalV2(expr: []const u8) !u64 {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    // https://en.wikipedia.org/wiki/Shunting-yard_algorithm
    var output = std.ArrayList(u8).init(allocator); // in reverse polish notation
    var operator_stack = std.ArrayList(u8).init(allocator);

    const top = struct { fn top(a: std.ArrayList(u8)) u8 {
        return a.items[a.items.len - 1];
    } }.top;

    for (expr) |c| {
        switch (c) {
            '0'...'9' => try output.append(c),
            '+', '*' => {
                while (operator_stack.items.len > 0 and 
                       top(operator_stack) == '+' and
                       top(operator_stack) != '(') {
                    try output.append(operator_stack.pop());
                } 
                
                try operator_stack.append(c);
            },
            '(' => try operator_stack.append(c),
            ')' => {
                while (top(operator_stack) != '(') {
                    try output.append(operator_stack.pop());
                }

                _ = operator_stack.pop(); // discard '('
            },
            else => {}
        }
    }

    while (operator_stack.items.len > 0) {
        try output.append(operator_stack.pop());
    }

    var eval_stack = std.ArrayList(u64).init(allocator);
    for (output.items) |c| {
        switch (c) {
            '0'...'9' => try eval_stack.append(@intCast(u64, c - '0')),
            '+', '*' => {
                const a = eval_stack.pop();
                const b = eval_stack.pop();
                try eval_stack.append(if (c == '+') a + b else a * b);
            },
            else => unreachable,
        }
    }

    return eval_stack.items[0];
}

const expectEqual = std.testing.expectEqual;
test "eval" {
    expectEqual(@as(u64, 51),    eval("1 + (2 * 3) + (4 * (5 + 6))"));
    expectEqual(@as(u64, 26),    eval("2 * 3 + (4 * 5)"));
    expectEqual(@as(u64, 437),   eval("5 + (8 * 3 + 9 + 3 * 4 * 3)"));
    expectEqual(@as(u64, 12240), eval("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))"));
    expectEqual(@as(u64, 13632), eval("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2"));
}

test "evalV2" {
    expectEqual(@as(u64, 51),     try evalV2("1 + (2 * 3) + (4 * (5 + 6))"));
    expectEqual(@as(u64, 46),     try evalV2("2 * 3 + (4 * 5)"));
    expectEqual(@as(u64, 1445),   try evalV2("5 + (8 * 3 + 9 + 3 * 4 * 3)"));
    expectEqual(@as(u64, 669060), try evalV2("5 * 9 * (7 * 3 * 3 + 9 * 3 + (8 + 6 * 4))"));
    expectEqual(@as(u64, 23340),  try evalV2("((2 + 4 * 9) * (6 + 9 * 8 + 6) + 6) + 2 + 4 * 2"));
}
