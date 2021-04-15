const std = @import("std");
const math = std.math;

pub fn Vec(comptime S: usize, comptime T: type) type {
    return switch (S) {
        2 => struct {
            x: T,
            y: T,

            pub usingnamespace VecCommonFns(S, T, @This());

            pub fn init(x: T, y: T) @This() {
                return @This(){ .x = x, .y = y };
            }

            pub fn orthogonal(self: @This()) @This() {
                return .{ .x = -self.y, .y = self.x };
            }

            pub fn perpindicular(self: @This(), v: @This()) @This() {
                return .{ .x = -1 * (v.y - self.y), .y = v.x - self.x };
            }

            pub fn rotate(self: @This(), radians: f32) @This() {
                return .{
                    .x = self.x * std.math.cos(radians) - self.y * std.math.sin(radians),
                    .y = self.y * std.math.cos(radians) + self.x * std.math.sin(radians),
                };
            }

            pub fn angleToVec(radians: f32, length: f32) Vec2 {
                return .{ .x = math.cos(radians) * length, .y = math.sin(radians) * length };
            }

            pub fn angleBetween(self: Vec2, to: Vec2) f32 {
                return math.atan2(f32, to.y - self.y, to.x - self.x);
            }

            pub fn sub(self: @This(), x: T, y: T) @This() {
                return self.subv(init(x, y));
            }

            pub fn add(self: @This(), x: T, y: T) @This() {
                return self.addv(init(x, y));
            }

            pub fn mul(self: @This(), x: T, y: T) @This() {
                return self.mulv(init(x, y));
            }

            pub fn div(self: @This(), x: T, y: T) @This() {
                return self.divv(init(x, y));
            }

            pub fn replace(self: @This(), xo: ?T, yo: ?T) @This() {
                return @This(){
                    .x = if (xo) |x| x else self.x,
                    .y = if (yo) |y| y else self.y,
                };
            }
        },
        3 => struct {
            x: T,
            y: T,
            z: T,

            pub usingnamespace VecCommonFns(S, T, @This());

            pub fn init(x: T, y: T, z: T) @This() {
                return @This(){ .x = x, .y = y, .z = z };
            }

            pub fn cross(self: @This(), other: @This()) @This() {
                return @This(){
                    .x = self.y * other.z - self.z * other.y,
                    .y = self.z * other.x - self.x * other.z,
                    .z = self.x * other.y - self.y * other.x,
                };
            }

            pub fn sub(self: @This(), x: T, y: T, z: T) @This() {
                return self.subv(init(x, y, z));
            }

            pub fn add(self: @This(), x: T, y: T, z: T) @This() {
                return self.addv(init(x, y, z));
            }

            pub fn mul(self: @This(), x: T, y: T, z: T) @This() {
                return self.mulv(init(x, y, z));
            }

            pub fn div(self: @This(), x: T, y: T, z: T) @This() {
                return self.divv(init(x, y, z));
            }
        },
        4 => struct {
            x: T,
            y: T,
            z: T,
            w: T,

            pub usingnamespace VecCommonFns(S, T, @This());

            pub fn init(xv: T, yv: T, zv: T, wv: T) @This() {
                return @This(){ .v = .{ .x = x, .y = y, .z = z, .w = w } };
            }

            pub fn sub(self: @This(), x: T, y: T, z: T, w: T) @This() {
                return self.subv(init(x, y, z, w));
            }

            pub fn add(self: @This(), x: T, y: T, z: T, w: T) @This() {
                return self.addv(init(x, y, z, w));
            }

            pub fn mul(self: @This(), x: T, y: T, z: T, w: T) @This() {
                return self.mulv(init(x, y, z, w));
            }

            pub fn div(self: @This(), x: T, y: T, z: T, w: T) @This() {
                return self.divv(init(x, y, z, w));
            }
        },
        else => @compileError("Vec of size " ++ S ++ " is not supported"),
    };
}

fn VecCommonFns(comptime S: usize, comptime T: type, comptime This: type) type {
    const primitive_ops = struct {
        pub fn add(a: T, b: T) T {
            return a + b;
        }

        pub fn sub(a: T, b: T) T {
            return a - b;
        }

        pub fn mul(a: T, b: T) T {
            return a * b;
        }

        pub fn div(a: T, b: T) T {
            return a / b;
        }

        pub const sqrt = std.math.sqrt;
    };

    // Allow structs/unions/enums to override arithmetic operations
    const is_primitive = switch (@typeInfo(T)) {
        .Int, .Float => true,
        else => false,
    };
    return struct {
        const comp_add = if (is_primitive) primitive_ops.add else T.@"+";
        const comp_sub = if (is_primitive) primitive_ops.sub else T.@"-";
        const comp_mul = if (is_primitive) primitive_ops.mul else T.@"*";
        const comp_div = if (is_primitive) primitive_ops.div else T.@"/";
        const ZERO = if (is_primitive) 0 else T.@"ZERO";

        const comp_sqrt = switch (@typeInfo(T)) {
            .Int => @compileError("Where is this?"),
            .Float => primitive_ops.sqrt,
            else => T.@"sqrt",
        };

        pub fn getField(this: This, index: usize) T {
            return switch (index) {
                0 => this.x,
                1 => this.y,
                2 => if (@hasField(@This(), "z")) this.z else @panic("index out of bounds!"),
                3 => if (@hasField(@This(), "w")) this.w else @panic("index out of bounds!"),
                else => @panic("index out of bounds!"),
            };
        }

        pub fn getFieldMut(this: *This, index: usize) *T {
            return switch (index) {
                0 => &this.x,
                1 => &this.y,
                2 => if (@hasField(@This(), "z")) &this.z else @panic("index out of bounds!"),
                3 => if (@hasField(@This(), "w")) &this.w else @panic("index out of bounds!"),
                else => @panic("index out of bounds!"),
            };
        }

        pub fn subv(self: This, other: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = comp_sub(self.getField(i), other.getField(i));
            }

            return res;
        }

        pub fn addv(self: This, other: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = comp_add(self.getField(i), other.getField(i));
            }

            return res;
        }

        pub fn mulv(self: This, other: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = comp_mul(self.getField(i), other.getField(i));
            }

            return res;
        }

        pub fn divv(self: This, other: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = comp_div(self.getField(i), other.getField(i));
            }

            return res;
        }

        pub fn scale(self: This, scal: T) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = comp_mul(self.getField(i), scal);
            }

            return res;
        }

        pub fn scaleDiv(self: This, scal: T) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = comp_div(self.getField(i), scal);
            }

            return res;
        }

        pub fn scaleDivFloor(self: This, scal: T) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = @divFloor(self.getField(i), scal);
            }

            return res;
        }

        pub fn normalize(self: This) This {
            const mag = self.magnitude();
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = self.getField(i) / mag;
            }

            return res;
        }

        pub fn maxComponentsv(self: This, other: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = std.math.max(self.getField(i), other.getField(i));
            }

            return res;
        }

        pub fn minComponentsv(self: This, other: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = std.math.min(self.getField(i), other.getField(i));
            }

            return res;
        }

        pub fn clampv(self: This, min: This, max: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = math.clamp(self.getField(i), min.getField(i), max.getField(i));
            }

            return res;
        }

        pub fn magnitudeSq(self: This) T {
            var sum: T = ZERO;
            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                sum = comp_add(sum, comp_mul(self.getField(i), self.getField(i)));
            }
            return sum;
        }

        pub fn magnitude(self: This) T {
            return comp_sqrt(self.magnitudeSq());
        }

        pub fn distanceSq(self: This, other: This) T {
            return self.subv(other).magnitudeSq();
        }

        pub fn distance(self: This, other: This) T {
            return self.subv(other).magnitude();
        }

        pub fn dotv(self: This, other: This) T {
            var sum: T = ZERO;
            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                sum = comp_add(sum, comp_mul(self.getField(i), other.getField(i)));
            }
            return sum;
        }

        pub fn eql(self: This, other: This) bool {
            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                if (self.getField(i) != other.getField(i)) {
                    return false;
                }
            }
            return true;
        }

        pub fn floor(self: This) This {
            var res: This = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = @floor(self.getField(i));
            }

            return res;
        }

        pub fn intToFloat(self: This, comptime F: type) Vec(S, F) {
            var res: Vec(S, F) = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = @intToFloat(F, self.getField(i));
            }

            return res;
        }

        pub fn floatToInt(self: This, comptime I: type) Vec(S, I) {
            var res: Vec(S, I) = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = @floatToInt(I, self.getField(i));
            }

            return res;
        }

        pub fn floatCast(self: This, comptime F: type) Vec(S, F) {
            var res: Vec(S, F) = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = @floatCast(F, self.getField(i));
            }

            return res;
        }

        pub fn intCast(self: This, comptime I: type) Vec(S, I) {
            var res: Vec(S, I) = undefined;

            comptime var i = 0;
            inline while (i < S) : (i += 1) {
                res.getFieldMut(i).* = @intCast(I, self.getField(i));
            }

            return res;
        }

        pub fn format(self: This, comptime fmt: []const u8, opt: std.fmt.FormatOptions, out: anytype) !void {
            comptime var i = 0;
            try out.writeAll("<");
            inline while (i < S) : (i += 1) {
                if (i != 0) try out.writeAll(", ");
                try std.fmt.formatType(self.getField(i), fmt, opt, out, 10);
            }
            try out.writeAll(">");
        }
    };
}

test "fixed point vectors" {
    const FixPoint = @import("./fixpoint.zig").FixPoint;
    const F = FixPoint(1, 60, 4);
    const V = Vec(2, F);

    // shortcuts
    const f = F.init;
    const v = V.init;

    std.testing.expectEqual(v(f(2, 3), f(5, 0)), v(f(1, 1), f(3, 0)).add(f(1, 2), f(2, 0)));
    std.testing.expectEqual(v(f(3, 0), f(6, 0)), v(f(1, 8), f(3, 0)).scale(f(2, 0)));
    std.testing.expectEqual(v(f(1, 8), f(3, 0)), v(f(3, 0), f(6, 0)).scaleDiv(f(2, 0)));
    std.testing.expectEqual(v(f(12, 0), f(6, 0)), v(f(1, 8), f(3, 0)).mul(f(8, 0), f(2, 0)));
    std.testing.expectEqual(v(f(1, 8), f(3, 0)), v(f(12, 0), f(6, 0)).div(f(8, 0), f(2, 0)));
    std.testing.expectEqual(f(1831, 6), v(f(42, 0), f(42, 0)).distance(v(f(1337, 0), f(1337, 0))));
    std.testing.expectEqual(f(66, 0), v(f(-6, 0), f(8, 0)).dotv(v(f(5, 0), f(12, 0))));

    const str = try std.fmt.allocPrint(std.testing.allocator, "{}", .{v(f(1, 0), f(2, 0))});
    defer std.testing.allocator.free(str);
    std.testing.expectEqualSlices(u8, "<1., 2.>", str);
}
