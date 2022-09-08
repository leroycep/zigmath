const std = @import("std");
const math = @import("./math.zig");

pub fn VoxelTraversal(comptime F: type, comptime I: type) type {
    const F_max = switch (F) {
        f32 => std.math.f32_max,
        f64 => std.math.f64_max,
        else => @compileError("Float type " ++ F ++ " not supported"),
    };
    return struct {
        current_voxel: math.Vec(3, I),
        last_voxel: math.Vec(3, I),
        step: math.Vec(3, I),
        tMax: math.Vec(3, F),
        tDelta: math.Vec(3, F),
        returned_first: bool = false,
        returned_last_voxel: bool = false,

        pub fn init(start: math.Vec(3, F), end: math.Vec(3, F)) @This() {
            var current_voxel = start.floor().floatToInt(I);
            const last_voxel = end.floor().floatToInt(I);
            const direction = end.subv(start);
            const step = math.Vec(3, I){
                .x = if (direction.x >= 0) 1 else -1,
                .y = if (direction.y >= 0) 1 else -1,
                .z = if (direction.z >= 0) 1 else -1,
            };
            const next_voxel_boundary = math.Vec(3, F){
                .x = if (step.x >= 0) @intToFloat(F, current_voxel.x + 1) else @intToFloat(F, current_voxel.x),
                .y = if (step.y >= 0) @intToFloat(F, current_voxel.y + 1) else @intToFloat(F, current_voxel.y),
                .z = if (step.z >= 0) @intToFloat(F, current_voxel.z + 1) else @intToFloat(F, current_voxel.z),
            };

            return @This(){
                .current_voxel = current_voxel,
                .last_voxel = last_voxel,
                .step = step,
                .tMax = math.Vec(3, F){
                    .x = if (direction.x != 0) (next_voxel_boundary.x - start.x) / direction.x else F_max,
                    .y = if (direction.y != 0) (next_voxel_boundary.y - start.y) / direction.y else F_max,
                    .z = if (direction.z != 0) (next_voxel_boundary.z - start.z) / direction.z else F_max,
                },
                .tDelta = math.Vec(3, F){
                    .x = if (direction.x != 0) 1.0 / direction.x * @intToFloat(F, step.x) else F_max,
                    .y = if (direction.y != 0) 1.0 / direction.y * @intToFloat(F, step.y) else F_max,
                    .z = if (direction.z != 0) 1.0 / direction.z * @intToFloat(F, step.z) else F_max,
                },
            };
        }

        pub fn next(this: *@This()) ?math.Vec(3, I) {
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
}
