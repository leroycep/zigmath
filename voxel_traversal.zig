const std = @import("std");
const math = @import("./math.zig");
const Vec3f = math.Vec3f;

pub const VoxelTraversal = struct {
    current_voxel: math.Vec(3, i32),
    last_voxel: math.Vec(3, i32),
    step: math.Vec(3, i32),
    tMax: Vec3f,
    tDelta: Vec3f,
    neg_diff: ?math.Vec(3, i32),
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
            .x = @intToFloat(f32, current_voxel.x + step.x),
            .y = @intToFloat(f32, current_voxel.y + step.y),
            .z = @intToFloat(f32, current_voxel.z + step.z),
        };

        var diff = math.Vec(3, i32).init(0, 0, 0);
        var neg_ray = false;
        if (current_voxel.x != last_voxel.x and direction.x < 0) {
            diff.x -= 1;
            neg_ray = true;
        }
        if (current_voxel.y != last_voxel.y and direction.y < 0) {
            diff.y -= 1;
            neg_ray = true;
        }
        if (current_voxel.z != last_voxel.z and direction.z < 0) {
            diff.z -= 1;
            neg_ray = true;
        }

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
            .neg_diff = if (neg_ray) diff else null,
        };
    }

    pub fn next(this: *@This()) ?math.Vec(3, i32) {
        if (!this.returned_first) {
            this.returned_first = true;
            return this.current_voxel;
        }
        if (this.neg_diff) |diff| {
            const pos = this.current_voxel;
            this.current_voxel = this.current_voxel.addv(diff);
            this.neg_diff = null;
            return pos;
        }
        if (this.last_voxel.eql(this.current_voxel)) {
            if (this.returned_last_voxel) {
                return null;
            } else {
                this.returned_last_voxel = true;
                return this.last_voxel;
            }
        }
        if (this.tMax.x < this.tMax.y) {
            if (this.tMax.x < this.tMax.z) {
                this.current_voxel.x += this.step.x;
                this.tMax.x += this.tDelta.x;
            } else {
                this.current_voxel.z += this.step.z;
                this.tMax.z += this.tDelta.z;
            }
        } else {
            if (this.tMax.y < this.tMax.z) {
                this.current_voxel.y += this.step.y;
                this.tMax.y += this.tDelta.y;
            } else {
                this.current_voxel.z += this.step.z;
                this.tMax.z += this.tDelta.z;
            }
        }
        return this.current_voxel;
    }
};
