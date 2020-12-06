const std = @import("std");
const input = @embedFile("data/input06");
usingnamespace @import("util.zig");

pub fn main() !void {
    print("[Part1] Count: {}", .{countAnyone(input)});
    print("[Part2] Count: {}", .{countEveryone(input)});
}

fn countAnyone(inputStr: []const u8) usize {
    var count: usize = 0;

    var reader = std.mem.split(inputStr, "\n\n");
    while (reader.next()) |group| {
        var answered = std.mem.zeroes([26]bool);
        for (group) |c| {
            if (c >= 'a' and c <= 'z' and !answered[c - 'a']) {
                answered[c - 'a'] = true;
                count += 1;
            }
        }
    }

    return count;
}

fn countEveryone(inputStr: []const u8) usize {
    var count: usize = 0;

    var reader = std.mem.split(inputStr, "\n\n");
    while (reader.next()) |group| {
        var everyoneAnswered = [_]bool{true} ** 26;
        var answered = [_]bool{false} ** 26;
        for (group) |c| {
            switch (c) {
                'a'...'z' => answered[c - 'a'] = true,
                '\n' => { 
                    andEach(&everyoneAnswered, &answered);
                    answered = [_]bool{false} ** 26;
                },
                else => {},
            }
        }

        if (group[group.len - 1] != '\n') {
            andEach(&everyoneAnswered, &answered);
        }

        for (everyoneAnswered) |v| {
            count += @boolToInt(v);
        }
    }

    return count;
}

const expectEqual = std.testing.expectEqual;
test "countAnyone" {
    expectEqual(@as(usize, 11), countAnyone(
        \\abc
        \\
        \\a
        \\b
        \\c
        \\
        \\ab
        \\ac
        \\
        \\a
        \\a
        \\a
        \\a
        \\
        \\b
    ));
}

test "countEveryone" {
    expectEqual(@as(usize, 6), countEveryone(
        \\abc
        \\
        \\a
        \\b
        \\c
        \\
        \\ab
        \\ac
        \\
        \\a
        \\a
        \\a
        \\a
        \\
        \\b
    ));
}
