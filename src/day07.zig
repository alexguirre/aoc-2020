const std = @import("std");
const input = @embedFile("data/input07");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const entries = try parse(allocator, input);
    print("[Part1] Count: {}", .{countShinyGold(entries)});
    print("[Part2] Count: {}", .{getNumberOfBagsInsideShinyGold(entries)});
}

const Bag = struct {
    color: []const u8,
    count: usize,
};

const Entries = std.StringHashMap([]const Bag);

fn parse(allocator: *std.mem.Allocator, inputStr: []const u8) !Entries {
    var entries = Entries.init(allocator);
    var reader = lines(inputStr);
    while (reader.next()) |line| {
        const colorEnd = std.mem.indexOf(u8, line, " bag") orelse return error.InvalidFormat;
        const color = line[0..colorEnd];

        var contents = line[colorEnd+" bags contain ".len..];
        var containedBags: []const Bag = &[_]Bag{};
        if (contents[0] != 'n') {
            var bags = std.ArrayList(Bag).init(allocator);
            while (true) {
                var bag: Bag = undefined;
                const countEnd = std.mem.indexOf(u8, contents, " ") orelse return error.InvalidFormat;
                
                bag.count = try std.fmt.parseUnsigned(usize, contents[0..countEnd], 10);
            
                const separator = if (bag.count == 1) " bag" else " bags";
                const containedColorEnd = std.mem.indexOfPos(u8, contents, countEnd + 1, separator) orelse return error.InvalidFormat;
                bag.color = contents[countEnd + 1..containedColorEnd];
                try bags.append(bag);

                if (contents[containedColorEnd + separator.len] == '.') {
                    break;
                } else {
                    contents = contents[containedColorEnd + separator.len + 2..];
                }
            }

            containedBags = bags.toOwnedSlice();
        }

        try entries.putNoClobber(color, containedBags);
    }

    return entries;
}

fn countShinyGold(entries: Entries) usize {
    var num: usize = 0;
    var it = entries.iterator();
    while (it.next()) |entry| {
        num += @boolToInt(canContainBag(entries, entry.key, "shiny gold"));
    }
    return num;
}

fn canContainBag(entries: Entries, containerColor: []const u8, comptime requiredColor: []const u8) bool {
    var containedBags = entries.get(containerColor).?;
    for (containedBags) |bag| {
        if (std.mem.eql(u8, bag.color, requiredColor) or canContainBag(entries, bag.color, requiredColor)) {
            return true;
        }
    }

    return false;
}

fn getNumberOfBagsInsideShinyGold(entries: Entries) usize {
    return getNumberOfBagsInside(entries, "shiny gold");
}

fn getNumberOfBagsInside(entries: Entries, color: []const u8) usize {
    var sum: usize = 0;
    var containedBags = entries.get(color).?;
    for (containedBags) |bag| {
        sum += bag.count + bag.count * getNumberOfBagsInside(entries, bag.color);
    }

    return sum;
}

const expectEqual = std.testing.expectEqual;
test "countShinyGold" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(usize, 4), countShinyGold(try parse(allocator, 
        \\light red bags contain 1 bright white bag, 2 muted yellow bags.
        \\dark orange bags contain 3 bright white bags, 4 muted yellow bags.
        \\bright white bags contain 1 shiny gold bag.
        \\muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
        \\shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
        \\dark olive bags contain 3 faded blue bags, 4 dotted black bags.
        \\vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
        \\faded blue bags contain no other bags.
        \\dotted black bags contain no other bags.
    )));
}

test "getNumberOfBagsInsideShinyGold" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(usize, 32), getNumberOfBagsInsideShinyGold(try parse(allocator, 
        \\light red bags contain 1 bright white bag, 2 muted yellow bags.
        \\dark orange bags contain 3 bright white bags, 4 muted yellow bags.
        \\bright white bags contain 1 shiny gold bag.
        \\muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
        \\shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
        \\dark olive bags contain 3 faded blue bags, 4 dotted black bags.
        \\vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
        \\faded blue bags contain no other bags.
        \\dotted black bags contain no other bags.
    )));

    expectEqual(@as(usize, 126), getNumberOfBagsInsideShinyGold(try parse(allocator, 
        \\shiny gold bags contain 2 dark red bags.
        \\dark red bags contain 2 dark orange bags.
        \\dark orange bags contain 2 dark yellow bags.
        \\dark yellow bags contain 2 dark green bags.
        \\dark green bags contain 2 dark blue bags.
        \\dark blue bags contain 2 dark violet bags.
        \\dark violet bags contain no other bags.
    )));
}