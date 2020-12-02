const std = @import("std");
const input = @embedFile("data/input02");
usingnamespace @import("util.zig");

pub fn main() !void {
    var valid_count1: usize = 0;
    var valid_count2: usize = 0;
    var reader = LineIterator.init(input);
    while (reader.next()) |line| {
        const e = Entry.parse(line) orelse return error.InvalidEntryFormat;

        if (e.isValid1()) {
            valid_count1 += 1;
        }
        
        if (e.isValid2()) {
            valid_count2 += 1;
        }
    }

    print("[Part1] Number of valid passwords: {}", .{valid_count1});
    print("[Part2] Number of valid passwords: {}", .{valid_count2});
}

const Entry = struct {
    const Self = @This();
    
    policy_min: usize,
    policy_max: usize,
    policy_char: u8,
    password: []const u8,

    pub fn isValid1(self: Self) bool {
        var count: usize = 0;
        for (self.password) |c| {
            if (c == self.policy_char) {
                count += 1;
            }
        }

        return count >= self.policy_min and count <= self.policy_max;
    }
    
    pub fn isValid2(self: Self) bool {
        const index1 = self.policy_min - 1;
        const index2 = self.policy_max - 1;

        const match1 = self.password[index1] == self.policy_char;
        const match2 = self.password[index2] == self.policy_char;
        return match1 != match2;
    }

    pub fn parse(line: []const u8) ?Entry {
        var tokenizer = std.mem.tokenize(line, " ");

        const min_max = tokenizer.next() orelse return null;
        const min_max_separator = std.mem.indexOf(u8, min_max, "-") orelse return null;
        const min = std.fmt.parseUnsigned(usize, min_max[0..min_max_separator], 10) catch return null;
        const max = std.fmt.parseUnsigned(usize, min_max[min_max_separator+1..], 10) catch return null;

        const char = tokenizer.next() orelse return null;

        const password = tokenizer.rest();

        return Entry {
            .policy_min = min,
            .policy_max = max,
            .policy_char = char[0],
            .password = password,
        };
    }
};