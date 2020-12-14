const std = @import("std");
const input = @embedFile("data/input14");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    const part1 = getSum(allocator, input, .v1);
    const part2 = getSum(allocator, input, .v2);

    print("[Part1] Sum: {}", .{part1});
    print("[Part2] Sum: {}", .{part2});
}

const Version = enum { v1, v2 };

const State = struct {
    const MemoryMap = std.AutoHashMap(u64, u64);

    maskX: u64,
    mask1: u64,
    memory: MemoryMap,

    pub fn init(allocator: *std.mem.Allocator) State {
        return .{
            .maskX = 0,
            .mask1 = 0,
            .memory = MemoryMap.init(allocator),
        };
    }
};

fn setMask(state: *State, mask: []const u8) void {
    std.debug.assert(mask.len == 36);

    state.maskX = 0;
    state.mask1 = 0;

    for (mask) |c, i| {
        state.maskX |= @intCast(u64, @boolToInt(c == 'X')) << @intCast(u6, 35 - i);
        state.mask1 |= @intCast(u64, @boolToInt(c == '1')) << @intCast(u6, 35 - i);
    }
}

inline fn applyMaskV1(state: *const State, value: u64) u64 {
    return (value & state.maskX) | state.mask1;
}

fn writeMemory(state: *State, address: u64, value: u64, comptime version: Version) void {
    switch (version) {
        .v1 => state.memory.put(address, applyMaskV1(state, value)) catch @panic("memory failed"),
        .v2 => {
            var addr = address;
            addr &= ~state.maskX; // If the bitmask bit is 0, the corresponding memory address bit is unchanged.
            addr |= state.mask1;  // If the bitmask bit is 1, the corresponding memory address bit is overwritten with 1.

            const num_floating_bits = @popCount(u64, state.maskX);
            const num_variations = std.math.pow(u64, 2, num_floating_bits);
            var variation_index: u64 = 0;
            while (variation_index < num_variations) : (variation_index += 1) {
                // take the bits from variation index and place them in floating_addr as the X mask indicates
                var floating_addr = addr;
                var floating_bit_index: u6 = 0;
                var variation_bit_index: u6 = 0;
                while (variation_bit_index < 36) : (variation_bit_index += 1) {
                    // get current bit
                    const variation_bit = (variation_index & (@as(u64, 1) << variation_bit_index)) >> variation_bit_index;

                    // find where the bit needs to be placed
                    while ((state.maskX & (@as(u64, 1) << floating_bit_index)) == 0) : (floating_bit_index +%= 1) {}

                    // place the bit
                    floating_addr |= variation_bit << floating_bit_index;
                    floating_bit_index +%= 1;
                }

                state.memory.put(floating_addr, value) catch @panic("memory failed");
            }
        },
    }
}

fn execute(state: *State, inputStr: []const u8, comptime version: Version) void {
    var reader = lines(inputStr);
    while (reader.next()) |line| {
        switch (std.mem.readIntSliceNative(u32, line[0..4])) {
            std.mem.readIntSliceNative(u32, "mask") => {
                setMask(state, line[7..]);
            },
            std.mem.readIntSliceNative(u32, "mem[") => {
                const addrEnd = std.mem.indexOf(u8, line[4..], "]").?;
                const addr = std.fmt.parseUnsigned(u64, line[4..(4+addrEnd)], 10) catch @panic("invalid address");
                const value = std.fmt.parseUnsigned(u64, line[(4+addrEnd+4)..], 10) catch @panic("invalid value");
                writeMemory(state, addr, value, version);
            },
            else => @panic("invalid instruction"),
        }
    }
}

fn getSum(allocator: *std.mem.Allocator, inputStr: []const u8, comptime version: Version) u64 {
    var s = State.init(allocator);
    execute(&s, inputStr, version);

    var sum: u64 = 0;
    var it = s.memory.iterator();
    while (it.next()) |p| {
        sum += @intCast(u64, p.value);
    }

    return sum;
}

const expectEqual = std.testing.expectEqual;
test "getSum" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(u64, 165), getSum(allocator, testInput1, .v1));
    expectEqual(@as(u64, 208), getSum(allocator, testInput2, .v2));
}

const testInput1 =
    \\mask = XXXXXXXXXXXXXXXXXXXXXXXXXXXXX1XXXX0X
    \\mem[8] = 11
    \\mem[7] = 101
    \\mem[8] = 0
;
const testInput2 =
    \\mask = 000000000000000000000000000000X1001X
    \\mem[42] = 100
    \\mask = 00000000000000000000000000000000X0XX
    \\mem[26] = 1
;