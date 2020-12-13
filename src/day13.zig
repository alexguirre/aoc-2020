const std = @import("std");
const input = @embedFile("data/input13");
usingnamespace @import("util.zig");

pub fn main() !void {
    const data = parse(input);
    
    const part1 = findEarliestBus(data);
    const part2 = findEarliestTimestamp(data);

    print("[Part1] Earliest bus: {}", .{part1});
    print("[Part2] Earliest timestamp: {}", .{part2});
}

const Data = struct { timestamp: usize, bus_ids: []const ?usize };
fn parse(comptime inputStr: []const u8) Data {
    comptime {
        @setEvalBranchQuota(10000);
        var reader = lines(inputStr);
        const timestamp = std.fmt.parseUnsigned(usize, reader.next().?, 10)  catch unreachable;
        var ids: []const ?usize = &[_]?usize{};
        const ids_line = reader.next().?;
        var ids_reader = std.mem.split(ids_line, ",");
        while (ids_reader.next()) |id_str| {
            const id = if (id_str[0] == 'x') null else (std.fmt.parseUnsigned(usize, id_str, 10) catch unreachable);
            ids = ids ++ [_]?usize{ id };
        }

        return comptime Data { .timestamp = timestamp, .bus_ids = ids };
    }
}

fn findEarliestBus(data: Data) usize {
    var earliest_id: usize = 0;
    var earliest_time_remaining: usize = std.math.maxInt(usize);

    for (data.bus_ids) |opt_id| {
        if (opt_id) |id| {
            const time_remaining = id - (data.timestamp % id);
            if (time_remaining < earliest_time_remaining) {
                earliest_id = id;
                earliest_time_remaining = time_remaining;
            }
        }
    }

    return earliest_id * earliest_time_remaining;
}

fn findEarliestTimestamp(data: Data) usize {
    const bus_ids = data.bus_ids;
    const num_matches_required = blk: {
        var n: usize = 0;
        for (bus_ids) |opt_id, time_offset| {
            if (opt_id) |id| {
                n += 1;
            }
        }

        break :blk n;
    };

    var step: usize = bus_ids[0].?;
    var num_matches_in_step: usize = 1;

    var timestamp: usize = step;
    while (true) : (timestamp += step) {
        var new_step: usize = step;
        var num_matches: usize = num_matches_in_step;
        var n: usize = 0;
        for (bus_ids) |opt_id, time_offset| {
            if (opt_id) |id| {
                n += 1;
                if (n <= num_matches_in_step) {
                    continue;
                }

                if ((@intCast(usize, timestamp + time_offset) % id) != 0) {
                    break;
                } else {
                    num_matches += 1;
                    new_step *= id;
                }
            }
        }

        if (num_matches == num_matches_required) {
            return timestamp;
        } else if (num_matches > num_matches_in_step) {
            step = new_step;
            num_matches_in_step = num_matches;
        }
    }

    unreachable;
}

const expectEqual = std.testing.expectEqual;
test "findEarliestBus" {
    expectEqual(@as(usize, 295), findEarliestBus(testData));
}

test "findEarliestTimestamp" {
    expectEqual(@as(usize, 1068781), findEarliestTimestamp(testData));
}

const testData = parse(
    \\939
    \\7,13,x,x,59,x,31,19
);
