const std = @import("std");
const input = @embedFile("data/input08");
usingnamespace @import("util.zig");

pub fn main() !void {
    var allocator_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    var insts = try parse(allocator, input);
    var part1 = (try execute(allocator, insts)).acc;
    print("[Part1] acc = {}", .{part1});

    var part2 = try fix(allocator, insts);
    print("[Part2] acc = {}", .{part2});
}

const Op = enum { nop, acc, jmp };
const Inst = struct {
    op: Op,
    arg: i32,
};

fn parse(allocator: *std.mem.Allocator, inputStr: []const u8) ![]Inst {
    var insts = std.ArrayList(Inst).init(allocator);

    var reader = lines(inputStr);
    while (reader.next()) |line| {
        const op = inline for (std.meta.fields(Op)) |opField| {
            const nameVal = std.mem.readIntSliceNative(u24, opField.name[0..3]);
            const inputVal = std.mem.readIntSliceNative(u24, line[0..3]);
            if (nameVal == inputVal) {
                break @intToEnum(Op, opField.value);
            }
        } else return error.UnknownInstruction;

        const arg = try std.fmt.parseInt(i32, line[4..], 10);

        try insts.append(.{ .op = op, .arg = arg });
    }

    return insts.toOwnedSlice();
}

const ExecutionResult = struct { acc: i32, loop: bool };
fn execute(allocator: *std.mem.Allocator, insts: []const Inst) !ExecutionResult {
    const alreadyExecuted = try allocator.alloc(bool, insts.len);
    defer allocator.free(alreadyExecuted);
    std.mem.set(bool, alreadyExecuted, false);

    var ip: isize = 0;
    var accumulator: i32 = 0;
    while (ip >= 0 and ip < insts.len) {
        const i = @intCast(usize, ip);
        const inst = insts[i];

        if (alreadyExecuted[i]) {
            return ExecutionResult { .acc = accumulator, .loop = true };
        }
        alreadyExecuted[i] = true;

        switch (inst.op) {
            .nop => ip += 1,
            .acc => { accumulator += inst.arg; ip += 1; },
            .jmp => ip += inst.arg,
        }
    }

    return ExecutionResult { .acc = accumulator, .loop = false };
}

fn fix(allocator: *std.mem.Allocator, insts: []Inst) !i32 {
    for (insts) |*inst| {
        switch (inst.op) {
            .nop, .jmp => {
                const origOp = inst.op;
                inst.op = if (inst.op == .nop) .jmp else .nop;
                var result = try execute(allocator, insts);
                if (!result.loop) {
                    return result.acc;
                }
                inst.op = origOp;
            },
            else => {},
        }
    }

    return error.Unfixable;
}

const expectEqual = std.testing.expectEqual;
const testSrc = 
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\jmp -4
        \\acc +6
    ;
test "execute" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(ExecutionResult { .acc = 5, .loop = true }, try execute(allocator, try parse(allocator, testSrc)));
}

test "fix" {
    var allocator_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer allocator_state.deinit();
    const allocator = &allocator_state.allocator;

    expectEqual(@as(i32, 8), try fix(allocator, try parse(allocator, testSrc)));
}