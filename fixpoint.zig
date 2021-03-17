const std = @import("std");

pub fn FixPoint(comptime signed: u1, comptime magnitude: u16, comptime fraction: u16) type {
    // Storage type
    const I = @Type(.{
        .Int = .{
            .signedness = if (signed == 1) .signed else .unsigned,
            .bits = magnitude + fraction,
        },
    });

    // Arithmetic type for multiplication
    const A = @Type(.{
        .Int = .{
            .signedness = if (signed == 1) .signed else .unsigned,
            .bits = magnitude + fraction + fraction,
        },
    });

    // integer type excluding the fraction
    const SM = @Type(.{
        .Int = .{
            .signedness = if (signed == 1) .signed else .unsigned,
            .bits = magnitude,
        },
    });

    // fraction integer type
    const F = @Type(.{
        .Int = .{
            .signedness = .unsigned,
            .bits = fraction,
        },
    });

    // fractional integer type for decimal formating
    const FFmt = @Type(.{
        .Int = .{
            .signedness = .unsigned,
            .bits = fraction + 4,
        },
    });

    const DENOM = (1 << fraction);

    return struct {
        i: I,

        pub fn init(int: SM, frac: F) @This() {
            // Invert the fractional bits for two's complement
            if (int < 0) {
                var new_frac: F = undefined;
                if (@subWithOverflow(F, frac, 1, &new_frac)) {
                    return .{ .i = (@intCast(I, int) << fraction) };
                } else {
                    return .{ .i = (@intCast(I, int - 1) << fraction) | @intCast(I, (~new_frac)) };
                }
            } else {
                return .{ .i = (@intCast(I, int) << fraction) | @intCast(I, frac) };
            }
        }

        pub fn add(this: @This(), int: SM, frac: F) @This() {
            return this.addf(init(int, frac));
        }

        pub fn addf(a: @This(), b: @This()) @This() {
            return .{ .i = a.i + b.i };
        }

        pub fn neg(this: @This()) @This() {
            return .{ .i = -this.i };
        }

        pub fn mul(this: @This(), int: SM, frac: F) @This() {
            return this.mulf(init(int, frac));
        }

        pub fn mulf(a: @This(), b: @This()) @This() {
            const aa = @intCast(A, a.i);
            const ba = @intCast(A, b.i);
            const ca = aa * ba;
            return .{ .i = @intCast(I, ca >> fraction) };
        }

        pub fn div(this: @This(), int: SM, frac: F) @This() {
            return this.divf(init(int, frac));
        }

        pub fn divf(a: @This(), b: @This()) @This() {
            const aa = @intCast(A, a.i) << fraction;
            const ba = @intCast(A, b.i);
            const ca = @divTrunc(aa, ba);
            return .{ .i = @intCast(I, ca) };
        }

        pub fn format(this: @This(), comptime fmt: []const u8, opt: std.fmt.FormatOptions, out: anytype) !void {
            const sm = @intCast(SM, this.i >> fraction);
            if (sm < 0 and this.i & (DENOM - 1) != 0) {
                try std.fmt.formatType(sm + 1, fmt, opt, out, 10);
            } else {
                try std.fmt.formatType(sm, fmt, opt, out, 10);
            }

            var f: FFmt = undefined;
            if (sm < 0) {
                f = @intCast(FFmt, ~@intCast(F, this.i & (DENOM - 1)) +% 1);
            } else {
                f = @intCast(FFmt, this.i & (DENOM - 1));
            }
            if (false) {
                // Format in fractional style instead of decimal
                try out.print("+{}/{}", .{ f, DENOM });
            } else {
                try out.writeByte('.');

                while (f > 0) {
                    f *= 10;
                    try out.writeByte('0' + (f >> fraction));
                    f &= (DENOM - 1);
                }
            }
        }
    };
}

test "Addition of 1:4:4" {
    const Fix = FixPoint(1, 4, 4);

    const a = Fix.init(-4, 3);
    const b = a.add(2, 5);
    std.testing.expectEqual(Fix.init(-1, 14), b);
}

test "Multiplcation of 1:4:4" {
    const fix = FixPoint(1, 4, 4).init;

    std.testing.expectEqual(fix(4, 6), fix(2, 3).mul(2, 0));
    std.testing.expectEqual(fix(6, 9), fix(2, 3).mul(3, 0));
    std.testing.expectEqual(fix(-2, 0), fix(-1, 0).mul(2, 0));
    std.testing.expectEqual(fix(-2, 3), fix(2, 3).mul(-1, 0));
}

test "Division of 1:4:4" {
    const fix = FixPoint(1, 4, 4).init;

    std.testing.expectEqual(fix(2, 3), fix(4, 6).div(2, 0));
    std.testing.expectEqual(fix(2, 3), fix(6, 9).div(3, 0));
    std.testing.expectEqual(fix(-1, 0), fix(-2, 0).div(2, 0));
    std.testing.expectEqual(fix(-2, 3), fix(2, 3).div(-1, 0));
}

test "Format 1:4:4" {
    const Fix = FixPoint(1, 4, 4);
    const fix = Fix.init;

    const TestCase = struct {
        expected: []const u8,
        input: Fix,
    };
    const test_cases = [_]TestCase{
        .{ .expected = "-1.", .input = fix(-1, 0) },
        .{ .expected = "-1.5", .input = fix(-1, 8) },
        .{ .expected = "4.1875", .input = fix(4, 3) },
        .{ .expected = "-4.1875", .input = fix(-4, 3) },
        .{ .expected = "-4.1875", .input = fix(4, 3).neg() },
    };

    for (test_cases) |case| {
        const str = try std.fmt.allocPrint(std.testing.allocator, "{}", .{case.input});
        defer std.testing.allocator.free(str);
        std.testing.expectEqualSlices(u8, case.expected, str);
    }
}

test "Init" {
    const fix = FixPoint(1, 4, 4).init;

    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b00010000)), fix(1, 0).i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11111110)), fix(0, 2).neg().i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11111111)), fix(0, 1).neg().i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11110000)), fix(-1, 0).i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11101111)), fix(-1, 1).i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11100000)), fix(-2, 0).i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b00100000)), fix(2, 0).i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11011000)), fix(-2, 8).i);
    std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11101000)), fix(-1, 8).i);
}
