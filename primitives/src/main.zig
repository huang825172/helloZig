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

    // TODO: Data saving
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

    pub fn Render(scene: Scene, fb: *Framebuffer) FbError!void {
        assert(scene.primitives.items[0].data.line.p2.x == 200);
        try fb.setPixel(1,1, Pixel {.color = Color { .r = 170 }} );
        // TODO: Rasterization algorithms
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
}

test "Elements & Renderer" {
    var scene = Scene.init();
    defer scene.free();

    try scene.primitives.append(
        Primitive {
            .data = PrimitiveInfo {
                .line = Line {
                    .p1 = Vertex { .x = 0, .y = 0 },
                    .p2 = Vertex { .x = 200, .y = 200 },
                }
            },
            .color = Color { .r = 255 },
            .lineWidth = .regular,
        }
    );

    assert(scene.primitives.items[0].data.line.p2.x == 200);

    var fb = try Framebuffer.init(1920, 1080);
    try Renderer.Render(scene, &fb);
    assert((try fb.getPixel(1,1)).color.r == 170);
}
