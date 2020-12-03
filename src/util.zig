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

    it: std.mem.TokenIterator,

    pub fn init(str: []const u8) Self {
        return .{
            .it = std.mem.tokenize(str, "\r\n"),
        };
    }

    pub fn next(self: *Self) ?[]const u8 {
        return self.it.next();
    }
};

pub fn print(comptime format: []const u8, args: anytype) void {
    std.debug.print(format ++ "\n", args);
}