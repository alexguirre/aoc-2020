const std = @import("std");

pub fn UIntLineIterator(comptime T: type) type {
    return struct {
        const Self = @This();
        const UInt = T;

        base: LineIterator,

        pub fn init(str: []const u8) Self {
            return .{
                .base = LineIterator.init(str),
            };
        }

        pub fn next(self: *Self) !?UInt {
            if (self.base.next()) |line| {
                return try std.fmt.parseUnsigned(UInt, line, 10);
            } else {
                return null;
            }
        }
    };
}

pub const LineIterator = struct {
    const Self = @This();

    str: []const u8,
    curr: usize = 0,

    pub fn init(str: []const u8) Self {
        return .{
            .str = str,
        };
    }

    pub fn next(self: *Self) ?[]const u8 {
        const new_line = "\r\n";

        if (self.curr >= self.str.len) {
            return null;
        }

        var result = self.str[self.curr..];
        if (std.ascii.indexOfIgnoreCase(result, new_line)) |new_line_pos| {
            result = result[0..new_line_pos];
            self.curr += result.len + new_line.len;
        } else {
            self.curr += result.len;
        }

        return result;
    }
};

pub fn print(comptime format: []const u8, args: anytype) void {
    std.debug.print(format ++ "\n", args);
}