const std = @import("std");
const math = @import("./math.zig");
const Vec3f = math.Vec3f;

pub const VoxelTraversal = struct {
    current_voxel: math.Vec(3, i32),
    last_voxel: math.Vec(3, i32),
    step: math.Vec(3, i32),
    tMax: Vec3f,
    tDelta: Vec3f,
    returned_first: bool = false,
    returned_last_voxel: bool = false,

    pub fn init(start: Vec3f, end: Vec3f) @This() {
        var current_voxel = start.floor().floatToInt(i32);
        const last_voxel = end.floor().floatToInt(i32);
        const direction = end.subv(start);
        const step = math.Vec(3, i32){
            .x = if (direction.x >= 0) 1 else -1,
            .y = if (direction.y >= 0) 1 else -1,
            .z = if (direction.z >= 0) 1 else -1,
        };
        const next_voxel_boundary = math.Vec3f{
            .x = if (step.x >= 0) @intToFloat(f32, current_voxel.x + 1) else @intToFloat(f32, current_voxel.x),
            .y = if (step.y >= 0) @intToFloat(f32, current_voxel.y + 1) else @intToFloat(f32, current_voxel.y),
            .z = if (step.z >= 0) @intToFloat(f32, current_voxel.z + 1) else @intToFloat(f32, current_voxel.z),
        };
        std.debug.print("next_voxel_boundary: {}\r", .{next_voxel_boundary});

        return @This(){
            .current_voxel = current_voxel,
            .last_voxel = last_voxel,
            .step = step,
            .tMax = math.Vec3f{
                .x = if (direction.x != 0) (next_voxel_boundary.x - start.x) / direction.x else std.math.f32_max,
                .y = if (direction.y != 0) (next_voxel_boundary.y - start.y) / direction.y else std.math.f32_max,
                .z = if (direction.z != 0) (next_voxel_boundary.z - start.z) / direction.z else std.math.f32_max,
            },
            .tDelta = math.Vec3f{
                .x = if (direction.x != 0) 1.0 / direction.x * @intToFloat(f32, step.x) else std.math.f32_max,
                .y = if (direction.y != 0) 1.0 / direction.y * @intToFloat(f32, step.y) else std.math.f32_max,
                .z = if (direction.z != 0) 1.0 / direction.z * @intToFloat(f32, step.z) else std.math.f32_max,
            },
        };
    }

    pub fn next(this: *@This()) ?math.Vec(3, i32) {
        if (!this.returned_first) {
            this.returned_first = true;
            return this.current_voxel;
        }
        if (this.last_voxel.eql(this.current_voxel)) {
            if (this.returned_last_voxel) {
                return null;
            } else {
                this.returned_last_voxel = true;
                return this.last_voxel;
            }
        }
        if (this.tMax.x < this.tMax.y and this.tMax.x < this.tMax.z) {
            this.current_voxel.x += this.step.x;
            this.tMax.x += this.tDelta.x;
        } else if (this.tMax.y < this.tMax.z) {
            this.current_voxel.y += this.step.y;
            this.tMax.y += this.tDelta.y;
        } else {
            this.current_voxel.z += this.step.z;
            this.tMax.z += this.tDelta.z;
        }
        return this.current_voxel;
    }
};
