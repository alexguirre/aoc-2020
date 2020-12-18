const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

// set this to true to link libc
const should_link_libc = false;

const test_files = [_][]const u8 {
    "src/day04.zig",
    "src/day05.zig",
    "src/day06.zig",
    "src/day07.zig",
    "src/day08.zig",
    "src/day09.zig",
    "src/day10.zig",
    "src/day11.zig",
    "src/day12.zig",
    "src/day13.zig",
    "src/day14.zig",
    "src/day15.zig",
    "src/day16.zig",
    "src/day17.zig",
    "src/day18.zig",
};

fn linkObject(b: *Builder, obj: *LibExeObjStep) void {
    if (should_link_libc) obj.linkLibC();

    // Add linking for packages or third party libraries here
}

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // Set up an exe for each day
    comptime var day = 1;
    inline while (day <= 25) : (day += 1) {
        @setEvalBranchQuota(100000); // this comptimePrint is pretty expensive
        const dayString = comptime std.fmt.comptimePrint("day{:0>2}", .{ day });
        const zigFile = "src/" ++ dayString ++ ".zig";

        
        const exe = b.addExecutable(dayString, zigFile);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        linkObject(b, exe);

        exe.install();

        const install_cmd = b.addInstallArtifact(exe);

        const install_step = b.step("install_" ++ dayString, "Install " ++ dayString ++ ".exe");
        install_step.dependOn(&install_cmd.step);

        const run_cmd = exe.run();
        run_cmd.step.dependOn(&install_cmd.step);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(dayString, "Run " ++ dayString);
        run_step.dependOn(&run_cmd.step);
    }

    // Set up a step to run all tests
    const test_step = b.step("test", "Run all tests");
    for (test_files) |file| {
        const test_cmd = b.addTest(file);
        test_cmd.setTarget(target);
        test_cmd.setBuildMode(mode);
        linkObject(b, test_cmd);

        test_step.dependOn(&test_cmd.step);
    }
}
