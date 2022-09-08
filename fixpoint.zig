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

    // Integer for sqrt
    const ISQRT = @Type(.{
        .Int = .{
            .signedness = .unsigned,
            .bits = magnitude + fraction + fraction,
        },
    });
    const ISQRT_SHIFT = @Type(.{
        .Int = .{
            .signedness = .unsigned,
            .bits = std.math.log2(magnitude + fraction + fraction),
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

    const FParse = @Type(.{
        .Int = .{
            .signedness = .unsigned,
            .bits = fraction * 4,
        },
    });

    const DENOM = (1 << fraction);

    return struct {
        i: I,

        pub const ZERO = @This(){ .i = 0 };

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

        pub fn initInteger(int: SM) @This() {
            return .{ .i = (@intCast(I, int) << fraction) };
        }

        // Support Vec operations
        pub const @"+" = addf;
        pub const @"-" = subf;
        pub const @"*" = mulf;
        pub const @"/" = divf;

        pub fn add(this: @This(), int: SM, frac: F) @This() {
            return this.addf(init(int, frac));
        }

        pub fn sub(this: @This(), int: SM, frac: F) @This() {
            return this.subf(init(int, frac));
        }

        pub fn mul(this: @This(), int: SM, frac: F) @This() {
            return this.mulf(init(int, frac));
        }

        pub fn div(this: @This(), int: SM, frac: F) @This() {
            return this.divf(init(int, frac));
        }

        // Unary operators
        pub fn neg(this: @This()) @This() {
            return .{ .i = -this.i };
        }

        pub fn sqrt(this: @This()) @This() {
            std.debug.assert(this.i > 0);
            const bitpos = @intCast(i16, fraction) - @intCast(i16, @clz(this.i));

            var x: ISQRT = undefined;
            if (bitpos > 0) {
                x = @as(ISQRT, DENOM) << @intCast(ISQRT_SHIFT, bitpos >> 1);
            } else if (bitpos < 0) {
                const shift = @truncate(ISQRT_SHIFT, @intCast(u16, (-bitpos) << 1));
                x = @as(ISQRT, DENOM) << shift;
            } else {
                x = DENOM;
            }

            const v = @intCast(ISQRT, this.i) << (fraction - 1);

            var prev: ISQRT = 0;
            while (prev > 2 + x or prev < x - 2) {
                prev = x;
                x = (x >> 1) + @divFloor(v, x);
            }

            return .{ .i = @intCast(I, x) };
        }

        // Binary operators
        pub fn addf(a: @This(), b: @This()) @This() {
            return .{ .i = a.i + b.i };
        }

        pub fn subf(a: @This(), b: @This()) @This() {
            return .{ .i = a.i - b.i };
        }

        pub fn mulf(a: @This(), b: @This()) @This() {
            const aa = @intCast(A, a.i);
            const ba = @intCast(A, b.i);
            const ca = aa * ba;
            return .{ .i = @intCast(I, ca >> fraction) };
        }

        pub fn divf(a: @This(), b: @This()) @This() {
            const aa = @intCast(A, a.i) << fraction;
            const ba = @intCast(A, b.i);
            const ca = @divTrunc(aa, ba);
            return .{ .i = @intCast(I, ca) };
        }

        pub fn gtf(a: @This(), b: @This()) bool {
            return a.i > b.i;
        }

        pub fn ltf(a: @This(), b: @This()) bool {
            return a.i < b.i;
        }

        pub fn eqf(a: @This(), b: @This()) bool {
            return a.i == b.i;
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
                    try out.writeByte('0' + @intCast(u8, f >> fraction));
                    f &= (DENOM - 1);
                }
            }
        }

        pub fn parse(str: []const u8, radixOr0: u8) !@This() {
            // Detect sign
            var startIdx: usize = 0;
            var is_neg = false;
            if (str.len == 0) return error.InvalidCharacter;
            if (str[0] == '+') {
                startIdx += 1;
                is_neg = false;
            }
            if (str[0] == '-') {
                startIdx += 1;
                is_neg = true;
            }

            // Detect radix
            var radix = radixOr0;
            if (radix == 0 and (str.len - startIdx) > 2 and str[startIdx] == '0') {
                switch (str[startIdx + 1]) {
                    'b' => {
                        startIdx += 2;
                        radix = 2;
                    },
                    'o' => {
                        startIdx += 2;
                        radix = 8;
                    },
                    'x' => {
                        startIdx += 2;
                        radix = 16;
                    },
                    else => radix = 10,
                }
            } else {
                radix = 10;
            }
            if (std.mem.indexOfScalar(u8, str, '.')) |decimal_point| {
                const int = try std.fmt.parseUnsigned(SM, str[startIdx..decimal_point], radix);

                var numerator: FParse = 0;
                var denom: FParse = 1;
                for (str[decimal_point + 1 ..]) |c| {
                    const digit = try std.fmt.charToDigit(c, radix);

                    if (numerator != 0) {
                        numerator = try std.math.mul(FParse, numerator, std.math.cast(FParse, radix) orelse return error.Overflow);
                    }
                    numerator = try std.math.add(FParse, numerator, std.math.cast(FParse, digit) orelse return error.Overflow);
                    denom = try std.math.mul(FParse, denom, std.math.cast(FParse, radix) orelse return error.Overflow);
                }

                const fixpoint = init(int, @intCast(F, @divFloor(numerator * DENOM, denom)));
                if (is_neg) {
                    return fixpoint.neg();
                } else {
                    return fixpoint;
                }
            } else {
                return initInteger(try std.fmt.parseInt(SM, str[startIdx..], radix));
            }
        }

        pub fn parseComptime(comptime str: []const u8) @This() {
            comptime {
                return parse(str, 0) catch unreachable;
            }
        }
    };
}

test "Addition of 1:4:4" {
    const Fix = FixPoint(1, 4, 4);

    const a = Fix.init(-4, 3);
    const b = a.add(2, 5);
    try std.testing.expectEqual(Fix.init(-1, 14), b);
}

test "Multiplcation of 1:4:4" {
    const fix = FixPoint(1, 4, 4).init;

    try std.testing.expectEqual(fix(4, 6), fix(2, 3).mul(2, 0));
    try std.testing.expectEqual(fix(6, 9), fix(2, 3).mul(3, 0));
    try std.testing.expectEqual(fix(-2, 0), fix(-1, 0).mul(2, 0));
    try std.testing.expectEqual(fix(-2, 3), fix(2, 3).mul(-1, 0));
}

test "Division of 1:4:4" {
    const fix = FixPoint(1, 4, 4).init;

    try std.testing.expectEqual(fix(2, 3), fix(4, 6).div(2, 0));
    try std.testing.expectEqual(fix(2, 3), fix(6, 9).div(3, 0));
    try std.testing.expectEqual(fix(-1, 0), fix(-2, 0).div(2, 0));
    try std.testing.expectEqual(fix(-2, 3), fix(2, 3).div(-1, 0));
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
        try std.testing.expectEqualSlices(u8, case.expected, str);
    }
}

test "Init" {
    const fix = FixPoint(1, 4, 4).init;

    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b00010000)), fix(1, 0).i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11111110)), fix(0, 2).neg().i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11111111)), fix(0, 1).neg().i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11110000)), fix(-1, 0).i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11101111)), fix(-1, 1).i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11100000)), fix(-2, 0).i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b00100000)), fix(2, 0).i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11011000)), fix(-2, 8).i);
    try std.testing.expectEqual(@bitCast(i8, @as(u8, 0b11101000)), fix(-1, 8).i);
}

fn expectApprox(maxErr: anytype, expected: @TypeOf(maxErr), got: @TypeOf(maxErr)) !void {
    const rel_err = expected.subf(got).divf(expected);
    if (rel_err.gtf(maxErr) or rel_err.ltf(maxErr.neg())) {
        std.log.err("expected approx {} (+/-{} rel), found {}", .{ expected, maxErr, got });
        return error.NotApproxEqual;
    }
}

test "sqrt" {
    const fix = FixPoint(1, 17, 4).init;

    try expectApprox(fix(0, 1), fix(2, 0), fix(4, 0).sqrt());
    try expectApprox(fix(0, 1), fix(3, 0), fix(9, 0).sqrt());
    try expectApprox(fix(0, 1), fix(4, 0), fix(16, 0).sqrt());
    try expectApprox(fix(0, 1), fix(5, 0), fix(25, 0).sqrt());
    try expectApprox(fix(0, 1), fix(6, 0), fix(36, 0).sqrt());
    try expectApprox(fix(0, 1), fix(7, 0), fix(49, 0).sqrt());
    try expectApprox(fix(0, 1), fix(255, 0), fix(65025, 0).sqrt());
}

test "sqrt very large number" {
    const fix = FixPoint(1, 60, 4).init;

    try expectApprox(fix(0, 1), fix(750_000_000, 0), fix(750_000_000 * 750_000_000, 0).sqrt());
}

test "parse from string" {
    const F = FixPoint(1, 50, 14);

    try expectApprox(F.init(0, 1), F.init(1, 0), try F.parse("1", 10));
    try expectApprox(F.init(0, 1), F.init(1, 4096), try F.parse("1.25", 10));
    try expectApprox(F.init(0, 1), F.init(-1, 4096), try F.parse("-1.25", 10));
    try expectApprox(F.init(0, 1), F.init(3, 2318), try F.parse("3.1415", 10));
    try expectApprox(F.init(0, 1), F.init(2, 11768), try F.parse("2.7182818284", 10));
    try expectApprox(F.init(0, 1), F.init(1, 4096), F.parseComptime("1.25"));
    try expectApprox(F.init(0, 1), F.init(16, 2368), F.parseComptime("0x10.25"));
    try expectApprox(F.init(0, 1), F.init(-16, 2368), F.parseComptime("-0x10.25"));
    try expectApprox(F.init(0, 1), F.init(1, 1), F.parseComptime("0b1.00000000000001"));

    try std.testing.expectError(error.InvalidCharacter, F.parse("0x-10.25", 0));
    try std.testing.expectError(error.InvalidCharacter, F.parse("10.-25", 0));
}
