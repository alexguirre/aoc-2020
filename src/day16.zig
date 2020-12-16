const std = @import("std");
const input = @embedFile("data/input16");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const result = scanTickets(allocator, input);

    print("[Part1] Error rate: {}", .{result.error_rate});
    print("[Part2] Departure product: {}", .{result.departure_product});
}

const Range = struct { 
    min: u32,
    max: u32,

    pub fn contains(self: Range, n: u32) bool { return self.min <= n and n <= self.max;}
};

const Class = struct {
    name: []const u8,
    range1: Range,
    range2: Range,
    position_bits: u32 = ~@as(u32, 0),

    pub fn isValid(self: Class, n: u32) bool { return self.range1.contains(n) or self.range2.contains(n); }
};

const Ticket = struct { values: []u32 };

const Result = struct { error_rate: u32, departure_product: u64 };

fn scanTickets(allocator: *std.mem.Allocator, input_str: []const u8) Result {
    var classes = std.ArrayList(Class).init(allocator);
    defer classes.deinit();

    var result = Result{ .error_rate = 0, .departure_product = 1 };

    var reader = lines(input_str);
    while (reader.next()) |line| {
        const class_name = line[0..std.mem.indexOf(u8, line, ":").?];
        if (std.mem.eql(u8, class_name, "your ticket")) {
            break;
        } else {
            var rule_tokens = std.mem.tokenize(line[class_name.len+2..], " -or");
            classes.append(.{
                .name = class_name,
                .range1 = .{
                    .min = std.fmt.parseUnsigned(u32, rule_tokens.next().?, 10) catch @panic("range1.min failed"),
                    .max = std.fmt.parseUnsigned(u32, rule_tokens.next().?, 10) catch @panic("range1.max failed"),
                },
                .range2 = .{
                    .min = std.fmt.parseUnsigned(u32, rule_tokens.next().?, 10) catch @panic("range2.min failed"),
                    .max = std.fmt.parseUnsigned(u32, rule_tokens.next().?, 10) catch @panic("range2.max failed"),
                },
            }) catch @panic("append failed");
        }
    }

    const my_ticket = parseTicket(allocator, classes.items.len, reader.next().?);
    _ = reader.next(); // skip "nearby tickets" header

    var tickets = std.ArrayList(Ticket).init(allocator);
    while (reader.next()) |line| {
        const ticket = parseTicket(allocator, classes.items.len, line);
        tickets.append(ticket) catch @panic("tickets append failed");

        for (ticket.values) |v| {
            for (classes.items) |class| {
                if (class.isValid(v)) {
                    break;
                }
            } else {
                result.error_rate += v;
                _ = tickets.pop();
                break;
            }
        }
    }

    for (tickets.items) |ticket| {
        for (ticket.values) |v, i| {
            const position_bit = @as(u32, 1) << @intCast(u5, i);

            for (classes.items) |*class| {
                if ((class.position_bits & position_bit) != 0 and !class.isValid(v)) {
                    class.position_bits &= ~position_bit;
                }
            }
        }
    }

    var useful_bits_mask: u32 = (@as(u32, 1) << @intCast(u5, classes.items.len)) - 1;
    var num_matched: usize = 0;
    while (num_matched < classes.items.len) : (num_matched += 1) {
        // find a class that only matches 1 field
        const class_index = for (classes.items) |c, i| {
            if (@popCount(u32, c.position_bits & useful_bits_mask) == 1) {
                break i;
            }
        } else @panic("multiple classes match the same fields");

        const class = classes.items[class_index];
        const field_index = @ctz(u32, class.position_bits);

        if (std.mem.startsWith(u8, class.name, "departure")) {
            result.departure_product *= my_ticket.values[field_index];
        }

        // remove that position bit from all the classes
        for (classes.items) |*c, i| {
            c.position_bits &= ~(@as(u32, 1) << @intCast(u5, field_index));
        }
    }

    return result;
}

fn parseTicket(allocator: *std.mem.Allocator, class_count: usize, line: []const u8) Ticket {
    const ticket = Ticket{ .values = allocator.alloc(u32, class_count) catch @panic("alloc failed") };
    var tokens = std.mem.tokenize(line, ",");
    var i: usize = 0;
    while (tokens.next()) |number_str| : (i += 1) {
        ticket.values[i] = std.fmt.parseUnsigned(u32, number_str, 10) catch @panic("ticket number failed");
    }
    return ticket;
}

const expectEqual = std.testing.expectEqual;
test "findTicketScanningErrorRate" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const result = scanTickets(allocator, testInput);
    expectEqual(@as(u32, 71), result.error_rate);
}
const testInput =
    \\class: 1-3 or 5-7
    \\row: 6-11 or 33-44
    \\seat: 13-40 or 45-50
    \\
    \\your ticket:
    \\7,1,14
    \\
    \\nearby tickets:
    \\7,3,47
    \\40,4,50
    \\55,2,20
    \\38,6,12
;