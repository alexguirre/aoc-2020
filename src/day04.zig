const std = @import("std");
const input = @embedFile("data/input04");
usingnamespace @import("util.zig");

pub fn main() !void {
    var numValid1: usize = 0;
    var numValid2: usize = 0;

    var reader = std.mem.split(input, "\n\n");
    while (reader.next()) |passport| {
        numValid1 += @boolToInt(isValidPassport(.one, passport));
        numValid2 += @boolToInt(isValidPassport(.two, passport));
    }

    print("[Part1] Number of valid passports: {}", .{numValid1});
    print("[Part2] Number of valid passports: {}", .{numValid2});
}

const Part = enum { one, two };
const RequiredField = enum { byr, iyr, eyr, hgt, hcl, ecl, pid }; 
fn isValidPassport(comptime part: Part, passport: []const u8) bool {
    const requiredFieldsMask = 0b0111_1111;

    var fieldsMask: u8 = 0;
    var fields = std.mem.tokenize(passport, " \n");
    while (fields.next()) |field| {
        inline for (std.meta.fields(RequiredField)) |f| {
            const bit = 1 << f.value;
            if ((fieldsMask & bit) == 0 and std.mem.startsWith(u8, field, f.name ++ ":")) {
                if (part == .one or (part == .two and isValidField(@intToEnum(RequiredField, f.value), field[4..]))) {
                    fieldsMask |= bit;
                }
                break;
            }
        }
    }

    return (fieldsMask & requiredFieldsMask) == requiredFieldsMask;
}

fn isValidField(field: RequiredField, value: []const u8) bool {
    return switch (field) {
        .byr => isValidYear(value, "1920", "2002"),
        .iyr => isValidYear(value, "2010", "2020"),
        .eyr => isValidYear(value, "2020", "2030"),

        .hgt => if (std.mem.endsWith(u8, value, "cm")) 
                    isNumberInRange(value[0..value.len-2], 3, "150", "193")
                else if (std.mem.endsWith(u8, value, "in"))
                    isNumberInRange(value[0..value.len-2], 2, "59", "76")
                else
                    false,

        .hcl => value.len == 7 and 
                value[0] == '#' and
                all(u8, value[1..], std.ascii.isXDigit),

        .ecl => value.len == 3 and (
                    std.mem.eql(u8, value, "amb") or
                    std.mem.eql(u8, value, "blu") or
                    std.mem.eql(u8, value, "brn") or
                    std.mem.eql(u8, value, "gry") or
                    std.mem.eql(u8, value, "grn") or
                    std.mem.eql(u8, value, "hzl") or
                    std.mem.eql(u8, value, "oth")
                ),
        .pid => value.len == 9 and all(u8, value, std.ascii.isDigit),
    };
}

fn isValidYear(yearStr: []const u8, comptime min: []const u8, comptime max: []const u8) bool {
    return isNumberInRange(yearStr, 4, min, max);
}

fn isNumberInRange(str: []const u8, comptime numDigits: usize, comptime min: []const u8, comptime max: []const u8) bool {
    return str.len == numDigits and
           std.mem.order(u8, str, min) != .lt and
           std.mem.order(u8, str, max) != .gt;
}

const expect = std.testing.expect;

test "isNumberInRange" {
    expect(isNumberInRange("10", 2, "10", "15"));
    expect(isNumberInRange("15", 2, "10", "15"));
    expect(isNumberInRange("12", 2, "10", "15"));
    expect(!isNumberInRange("8", 2, "10", "15"));
    expect(!isNumberInRange("20", 2, "10", "15"));
}

test "validateField" {
    expect(isValidField(.byr, "2002"));
    expect(!isValidField(.byr, "2003"));

    expect(isValidField(.hgt, "60in"));
    expect(isValidField(.hgt, "190cm"));
    expect(!isValidField(.hgt, "190in"));
    expect(!isValidField(.hgt, "190"));

    expect(isValidField(.hcl, "#123abc"));
    expect(!isValidField(.hcl, "#123abz"));
    expect(!isValidField(.hcl, "123abc"));

    expect(isValidField(.ecl, "brn"));
    expect(!isValidField(.ecl, "wat"));

    expect(isValidField(.pid, "000000001"));
    expect(!isValidField(.pid, "0123456789"));
}

test "isValidPassport" {
    expect(!isValidPassport(.two, "eyr:1972 cid:100 hcl:#18171d ecl:amb hgt:170 pid:186cm iyr:2018 byr:1926"));
    expect(!isValidPassport(.two, "iyr:2019 hcl:#602927 eyr:1967 hgt:170cm ecl:grn pid:012533040 byr:1946"));
    expect(!isValidPassport(.two, "hcl:dab227 iyr:2012 ecl:brn hgt:182cm pid:021572410 eyr:2020 byr:1992 cid:277"));
    expect(!isValidPassport(.two, "hgt:59cm ecl:zzz eyr:2038 hcl:74454a iyr:2023 pid:3556412378 byr:2007"));
    
    expect(isValidPassport(.two, "pid:087499704 hgt:74in ecl:grn iyr:2012 eyr:2030 byr:1980 hcl:#623a2f"));
    expect(isValidPassport(.two, "eyr:2029 ecl:blu cid:129 byr:1989 iyr:2014 pid:896056539 hcl:#a97842 hgt:165cm"));
    expect(isValidPassport(.two, "hcl:#888785 hgt:164cm byr:2001 iyr:2015 cid:88 pid:545766238 ecl:hzl eyr:2022"));
    expect(isValidPassport(.two, "iyr:2010 hgt:158cm hcl:#b6652a ecl:blu byr:1944 eyr:2021 pid:093154719"));
}