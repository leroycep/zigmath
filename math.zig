// Define common vector types
pub const Vec = @import("./vec.zig").Vec;
pub const Vec2i = Vec(2, i32);
pub const Vec2u = Vec(2, u32);
pub const Vec2f = Vec(2, f32);
pub const Vec3f = Vec(3, f32);

pub fn vec2i(x: i32, y: i32) Vec(2, i32) {
    return Vec(2, i32).init(x, y);
}

pub fn vec2u(x: u32, y: u32) Vec(2, u32) {
    return Vec(2, u32).init(x, y);
}

pub fn vec2f(x: f32, y: f32) Vec(2, f32) {
    return Vec(2, f32).init(x, y);
}

pub fn vec3f(x: f32, y: f32, z: f32) Vec(3, f32) {
    return Vec(3, f32).init(x, y, z);
}

pub fn vec2us(x: usize, y: usize) Vec(2, usize) {
    return Vec(2, usize).init(x, y);
}

pub fn vec2is(x: isize, y: isize) Vec(2, isize) {
    return Vec(2, isize).init(x, y);
}

// Define commmon matrix types
pub const Mat4 = @import("./matrix.zig").Mat4;
pub const Mat4f = Mat4(f32);

pub const VoxelTraversal = @import("./voxel_traversal.zig").VoxelTraversal;

pub const FixPoint = @import("./fixpoint.zig").FixPoint;

test {
    @import("std").testing.refAllDecls(@This());
}
