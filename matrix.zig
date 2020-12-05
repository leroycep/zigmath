const std = @import("std");
const math = std.math;
const Vec = @import("math.zig").Vec;

pub fn Mat4(comptime T: type) type {
    const W = 4;
    const H = 4;
    const SIZE = W * H;

    return struct {
        v: [SIZE]T,

        pub fn new(v: [SIZE]T) @This() {
            return .{
                .v = v,
            };
        }

        pub fn fill(val: T) @This() {
            var v: [SIZE]T = undefined;
            std.mem.set(T, &v, val);
            return .{
                .v = v,
            };
        }

        pub fn idx(x: usize, y: usize) usize {
            std.debug.assert(x < W);
            std.debug.assert(y < H);
            return y * H + x;
        }

        pub fn at(self: *@This(), x: usize, y: usize) *T {
            return &self.v[idx(x, y)];
        }

        pub fn get(self: @This(), x: usize, y: usize) T {
            return self.v[idx(x, y)];
        }

        pub fn vecMul(self: @This(), vec: Vec(4, T)) Vec(4, T) {
            var res: [4]T = [1]T{0} ** 4;

            var i: usize = 0;
            while (i < 4) : (i += 1) {
                var j: usize = 0;
                while (j < 4) : (j += 1) {
                    res[i] += vec.v[j] * self.get(i, j);
                }
            }

            return .{ .v = res };
        }

        pub fn mul(self: @This(), other: @This()) @This() {
            var res: @This() = fill(0);

            var i: usize = 0;
            while (i < H) : (i += 1) {
                var j: usize = 0;
                while (j < W) : (j += 1) {
                    var k: usize = 0;
                    while (k < H) : (k += 1) {
                        res.at(i, j).* += self.get(i, k) * other.get(k, j);
                    }
                }
            }

            return res;
        }

        pub fn ident() @This() {
            return .{
                .v = .{
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1,
                },
            };
        }

        pub fn translation(pos: Vec(3, T)) @This() {
            return .{
                .v = .{
                    1,       0,       0,       0,
                    0,       1,       0,       0,
                    0,       0,       1,       0,
                    pos.x(), pos.y(), pos.z(), 1,
                },
            };
        }

        pub fn perspective(fovRadians: T, aspect: T, near: T, far: T) @This() {
            const f = math.tan(math.pi * 0.5 - 0.5 * fovRadians);
            const rangeInv = 1.0 / (near - far);

            return .{
                .v = .{
                    f / aspect, 0, 0,                         0,
                    0,          f, 0,                         0,
                    0,          0, (near + far) * rangeInv,   -1,
                    0,          0, near * far * rangeInv * 2, 0,
                },
            };
        }

        pub fn lookAt(eye: Vec(3, T), target: Vec(3, T), up: Vec(3, T)) @This() {
            const f = target.subv(eye).normalize();
            const s = f.cross(up.normalize()).normalize();
            const u = s.cross(f);

            var res: @This() = undefined;

            res.at(0, 0).* = s.x;
            res.at(0, 1).* = s.y;
            res.at(0, 2).* = s.z;
            res.at(0, 3).* = -s.dotv(eye);
            res.at(1, 0).* = u.x;
            res.at(1, 1).* = u.y;
            res.at(1, 2).* = u.z;
            res.at(1, 3).* = -u.dotv(eye);
            res.at(2, 0).* = -f.x;
            res.at(2, 1).* = -f.y;
            res.at(2, 2).* = -f.z;
            res.at(2, 3).* = f.dotv(eye);
            res.at(3, 0).* = 0;
            res.at(3, 1).* = 0;
            res.at(3, 2).* = 0;
            res.at(3, 3).* = 1;

            return res;
        }

        pub fn format(self: @This(), comptime fmt: []const u8, opt: std.fmt.FormatOptions, out: anytype) !void {
            return std.fmt.format(out,
                \\ {}, {}, {}, {}
                \\ {}, {}, {}, {}
                \\ {}, {}, {}, {}
                \\ {}, {}, {}, {}
            , .{
                self.v[0],  self.v[1],  self.v[2],  self.v[3],
                self.v[4],  self.v[5],  self.v[6],  self.v[7],
                self.v[8],  self.v[9],  self.v[10], self.v[11],
                self.v[12], self.v[13], self.v[14], self.v[12],
            });
        }

        pub fn floatCast(self: @This(), comptime F: type) Mat4(F) {
            var res: Mat4(F) = undefined;

            var i: usize = 0;
            while (i < self.v.len) : (i += 1) {
                res.v[i] = @floatCast(F, self.v[i]);
            }

            return res;
        }

    };
}
