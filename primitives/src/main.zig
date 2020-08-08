const std = @import("std");
const assert = std.debug.assert;
const allocator = std.heap.page_allocator;

const FbError = error {
    CoordOutOfRange,
};

const Color = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
};

const Pixel = struct {
    zindex: u8 = 0,
    color: Color = Color {},
};

const Framebuffer = struct {
    pixels: []Pixel,
    width: u32,
    height: u32,
    
    pub fn init(comptime width: u32,comptime height: u32) anyerror!Framebuffer {
        const fb = Framebuffer {
            .pixels = try allocator.alloc(Pixel, width * height),
            .width = width,
            .height = height,
        };
        for (fb.pixels) |*p| {
            p.* = Pixel{};
        }
        return fb;
    }

    pub fn clear(self: Framebuffer, color: Color) void {
        for (self.pixels) |*p| {
            p.* = Pixel {
                .color = color,
            };
        }
    }

    pub fn setPixel(self: Framebuffer, x: u32, y: u32, pixel: Pixel) FbError!void {
        if (x > self.width or y > self.height) return FbError.CoordOutOfRange;
        self.pixels[self.width*(y-1)+(x-1)] = pixel;
    }

    pub fn getPixel(self: Framebuffer, x: u32, y: u32) FbError!Pixel {
        if (x > self.width or y > self.height) return FbError.CoordOutOfRange;
        return self.pixels[self.width*(y-1)+(x-1)];
    }

    pub fn free(self: Framebuffer) void {
        allocator.free(self.pixels);
    }

    pub fn save(self: Framebuffer, fileName: []const u8) anyerror!void {
        var strCache = std.ArrayList(u8).init(allocator);
        defer strCache.deinit();
        try strCache.appendSlice("P3\n");
        try strCache.appendSlice(blk: {
            var buf: [20]u8 = undefined;
            break :blk try intToString(self.width, &buf);
        });
        try strCache.append(' ');
        try strCache.appendSlice(blk: {
            var buf: [20]u8 = undefined;
            break :blk try intToString(self.height, &buf);
        });
        try strCache.appendSlice("\n255\n");
        for (self.pixels) |*p| {
            try strCache.appendSlice(blk: {
                var buf: [20]u8 = undefined;
                break :blk try intToString(p.*.color.r, &buf);
            });
            try strCache.append(' ');
            try strCache.appendSlice(blk: {
                var buf: [20]u8 = undefined;
                break :blk try intToString(p.*.color.g, &buf);
            });
            try strCache.append(' ');
            try strCache.appendSlice(blk: {
                var buf: [20]u8 = undefined;
                break :blk try intToString(p.*.color.b, &buf);
            });
            try strCache.append('\n');
        }
        try std.fs.cwd().writeFile(fileName, strCache.items);
    }

    fn intToString(int: u32, buf: []u8) ![]const u8 {
        return try std.fmt.bufPrint(buf, "{}", .{int});
    }
};

const Vertex = struct {
    x: f32 = 0,
    y: f32 = 0,
};

const Line = struct {
    p1: Vertex,
    p2: Vertex,
};

const Circle = struct {
    center: Vertex,
    r: f32 = 0,
};

const PrimitiveType = enum {
    line,
    circle,
};

const PrimitiveInfo = union(PrimitiveType) {
    line: Line,
    circle: Circle,
};

const LineWidthType = enum {
    light,
    regular,
    bold,
    custom,
};

const LineWidthInfo = union(LineWidthType) {
    light,
    regular,
    bold,
    custom: u32,
};

const Primitive = struct {
    data: PrimitiveInfo,
    color: Color,
    lineWidth: LineWidthInfo,
};

const Scene = struct {
    primitives: std.ArrayList(Primitive),
    
    pub fn init() Scene {
        return Scene {
            .primitives = std.ArrayList(Primitive).init(allocator),
        };
    }

    pub fn free(self: Scene) void {
        self.primitives.deinit();
    }
};

const ParallelMode = enum {
    singleThread,
    multiThread,
};

const Renderer = struct {
    parallelMode: ParallelMode,

    pub fn Render(self: Renderer, scene: Scene, fb: *Framebuffer) anyerror!void {
        for (scene.primitives.items) |item, i| {
            switch (item.data) {
                PrimitiveType.line => |line| {
                    if (self.parallelMode == ParallelMode.singleThread) {
                        const x0: i32 = @floatToInt(i32, line.p1.x);
                        const y0: i32 = @floatToInt(i32, line.p1.y);
                        var x1: i32 = @floatToInt(i32, line.p2.x);
                        var y1: i32 = @floatToInt(i32, line.p2.y);
                        const dx = try std.math.absInt(x1 - x0);
                        const dy = try std.math.absInt(y1 - y0);
                        var p = 2 * dy - dx;
                        const twoDy = 2 * dy;
                        const twoDyMinusDx = 2 * (dy - dx);
                        var x: i32 = 0;
                        var y: i32 = 0;
                        if (x0 > x1) {
                            x = x1;
                            y = y1;
                            x1 = x0;
                        } else {
                            x = x0;
                            y = y0;
                        }
                        try fb.setPixel(@intCast(u32, x), @intCast(u32, y), Pixel {
                            .color = Color {
                                .r = 255, .g = 255, .b = 255,
                            }
                        });
                        while (x < x1) {
                            x += 1;
                            if (p < 0) {
                                p += twoDy;
                            } else {
                                y += 1;
                                p += twoDyMinusDx;
                            }
                            try fb.setPixel(@intCast(u32, x), @intCast(u32, y), Pixel {
                                .color = Color {
                                    .r = 255, .g = 255, .b = 255,
                                }
                            });
                        }
                    }
                },
                PrimitiveType.circle => |circle| {
                    std.debug.print("Circle\n", .{});
                },
            }
        }
    }
};

pub fn main() anyerror!void {
    std.debug.warn("Primitives.\n", .{});
}

test "Framebuffer" {
    var fb = try Framebuffer.init(1920, 1080);
    defer fb.free();

    if (fb.setPixel(1921, 1080, Pixel{})) {
        unreachable;
    } else |err| {
        assert(err == FbError.CoordOutOfRange);
    }

    for (fb.pixels) |*p| {
        assert(p.*.color.a == 0);
    }

    if (fb.setPixel(1920, 1080, Pixel{.color = Color {.a = 1}})) {
        assert((try fb.getPixel(1920, 1080)).color.a == 1);
    } else |err| {
        unreachable;
    }

    fb.clear(Color {});
    assert((try fb.getPixel(1920, 1080)).color.a == 0);

    fb.clear(Color { .g = 255 });
    // Save pass
    // try fb.save("save.ppm");
}

test "Elements & Renderer" {
    var scene = Scene.init();
    defer scene.free();

    try scene.primitives.append(
        Primitive {
            .data = PrimitiveInfo {
                .line = Line {
                    .p1 = Vertex { .x = 400, .y = 400 },
                    .p2 = Vertex { .x = 800, .y = 200 },
                }
            },
            .color = Color { .r = 255 },
            .lineWidth = .regular,
        }
    );

    var fb = try Framebuffer.init(1920, 1080);
    const ren = Renderer { .parallelMode = ParallelMode.singleThread };
    try ren.Render(scene, &fb);

    try fb.save("primitive.ppm");
}
