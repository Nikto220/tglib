//! A submodule for collision detection

const rl = @import("raylib");

pub const MAX_HITS_PER_FRAME = 32;

pub const Collider = struct {
    position: rl.Vector3,
    size: rl.Vector3,
    collider_type: CollisionType,

    pub inline fn init(position: rl.Vector3, size: rl.Vector3, collision_type: CollisionType) Collider {
        return Collider{.position = position, .size = size, .collider_type = collision_type};
    }

    pub inline fn changeSize(self: *Collider, to_y: f32) void {
        const feet_pos = self.position.y - self.size.y/2.0;
        self.position.y = feet_pos + to_y/2.0;
        self.size.y = to_y;
    }

    pub inline fn checkCollision(self: *Collider, other: *const Collider) ?CollisionType {
        if (self.position.x - self.size.x/2.0 < other.position.x + other.size.x/2.0 and
            self.position.x + self.size.x/2.0 > other.position.x - other.size.x/2.0 and
            self.position.y - self.size.y/2.0 < other.position.y + other.size.y/2.0 and
            self.position.y + self.size.y/2.0 > other.position.y - other.size.y/2.0 and
            self.position.z - self.size.z/2.0 < other.position.z + other.size.z/2.0 and
            self.position.z + self.size.z/2.0 > other.position.z - other.size.z/2.0) {
            return self.*.collider_type;
        }
        else return null;
    }
};

pub const PhysicsBody = struct {
    velocity: rl.Vector3,
};

pub const CollisionObject = union(enum) {
    box: Box,
    collision_box: Box,

    pub fn render(self: *CollisionObject) void {
        switch (self.*) {
            .box => |*box| box.render(),
            .collision_box => {},
        }
    }

    pub inline fn checkCollision(self: *CollisionObject, other: *const Collider) ?CollisionType {
        switch (self.*) {
            .box => |*box| return box.collider.checkCollision(other),
            .collision_box => |*box| return box.collider.checkCollision(other)
        }
    }

    pub inline fn getCollider(self: *CollisionObject) *Collider {
        switch (self.*) {
            .box => |*box| return &box.collider,
            .collision_box => |*box| return &box.collider
        }
    }
};

pub const CollisionType = union(enum) {
    solid: void,
    passable: void,
    action: struct {
        on_enter: ?*const fn(*Collider, *Collider, *PhysicsBody) void = null,
        on_exit: ?*const fn(*Collider, *Collider, *PhysicsBody) void = null,
        was_done: bool = false
    },
    player: void,

    pub inline fn doAction(self: *CollisionType, col: *Collider, other_col: *Collider, other_physics_body: *PhysicsBody) void {
        switch (self.*) {
            .action => |*action| if (!action.*.was_done) {
                if (action.on_enter) |callback| {
                    callback(col, other_col, other_physics_body);
                }
                action.*.was_done = true;
            },
            else => {},
        }
    }

    pub inline fn doExit(self: *CollisionType, col: *Collider, other_col: *Collider, other_physics_body: *PhysicsBody) void {
        switch (self.*) {
            .action => |*action| {
                if (action.on_exit) |callback| {
                    callback(col, other_col, other_physics_body);
                }
                action.was_done = false;
            },
            else => {},
        }
    }
};

pub const Box = struct {
    collider: Collider,
    color: rl.Color,
    outline_color: rl.Color,

    pub fn render(self: Box) void {
        rl.drawCubeV(self.collider.position, self.collider.size, self.color);
        rl.drawCubeWiresV(self.collider.position, self.collider.size, self.outline_color);
    }
};
