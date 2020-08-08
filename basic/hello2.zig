const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;
const mem = std.mem;
const fmt = std.fmt;
const builtin = std.builtin;

test "basic slices" {
    var array = [_]i32 {1,2,3,4};
    var known_at_runtime_zero: usize = 0;
    const slice = array[known_at_runtime_zero..array.len];
    print("array.len = {}\n", .{array.len});
    assert(&slice[0] == &array[0]);
    assert(slice.len == array.len);

    assert(@TypeOf(slice.ptr) == [*]i32);
    assert(@TypeOf(&slice[0]) == *i32);
    assert(@ptrToInt(slice.ptr) == @ptrToInt(&slice[0]));

    // slice[10] += 1;
}

test "using slices for strings" {
    const hello: []const u8 = "hello";
    const world: []const u8 = "世界";

    var all_together: [100]u8 = undefined;
    const all_together_slice = all_together[0..];
    const hello_world = try fmt.bufPrint(all_together_slice, "{} {}", .{hello, world});
    
    assert(mem.eql(u8, hello_world, "hello 世界"));
}

test "slice pointer" {
    var array: [10]u8 = undefined;
    const ptr = &array;

    const slice = ptr[0..5];
    slice[2] = 3;
    assert(slice[2] == 3);

    assert(@TypeOf(slice) == *[5]u8);

    const slice2 = slice[2..3];
    assert(slice2.len == 1);
    assert(slice2[0] == 3);
}

test "null terminated slice" {
    const slice: [:0]const u8 = "hello";

    assert(slice.len == 5);
    assert(slice[5] == 0);
}

const Point = struct {
    x: f32,
    y: f32,
};

const Point2 = packed struct {
    x: f32,
    y: f32,
};

const p = Point {
    .x = 0.12,
    .y = 0.34,
};

var p2 = Point {
    .x = 0.12,
    .y = undefined,
};

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn init(x: f32, y: f32, z:f32) Vec3 {
        return Vec3 {
            .x = x,
            .y = y,
            .z = z,
        };
    }

    pub fn dot(self: Vec3, other: Vec3) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
};

test "dot product" {
    const v1 = Vec3.init(1.0, 0.0, 0.0);
    const v2 = Vec3.init(0.0, 1.0, 0.0);
    assert(v1.dot(v2) == 0.0);

    assert(Vec3.dot(v1, v2) == 0.0);
}

const Empty = struct {
    pub const PI = 3.14;
};

test "struct namespaced variable" {
    assert(Empty.PI == 3.14);
    assert(@sizeOf(Empty) == 0);

    const does_nothing = Empty {};
}

fn setYBasedOnX(x: *f32, y: f32) void {
    const point = @fieldParentPtr(Point, "x", x);
    point.y = y;
}

test "field parent pointer" {
    var point = Point {
        .x = 0.1234,
        .y = 0.5678,
    };
    setYBasedOnX(&point.x, 0.9);
    assert(point.y == 0.9);
}

fn LinkedList(comptime T: type) type {
    return struct {
        pub const Node = struct {
            prev: ?*Node,
            next: ?*Node,
            data: T,
        };
        
        first: ?*Node,
        last: ?*Node,
        len: usize,
    };
}

test "linked list" {
    assert(LinkedList(i32) == LinkedList(i32));

    var list = LinkedList(i32) {
        .first = null,
        .last = null,
        .len = 0,
    };
    assert(list.len == 0);

    const ListOfInts = LinkedList(i32);
    assert(ListOfInts == LinkedList(i32));

    var node = ListOfInts.Node {
        .prev = null,
        .next = null,
        .data = 1234,
    };

    var list2 = LinkedList(i32) {
        .first = &node,
        .last = &node,
        .len = 1,
    };
    assert(list2.first.?.data == 1234);
    // ?
}

const DFoo = struct {
    a: i32 = 1234,
    b: i32,
};

test "default struct initialization fields" {
    const x = DFoo {
        .b = 5,
    };
    if (x.a + x.b != 1239) {
        @compileError("cmpt known");
    }
}

const Full = packed struct {
    number: u16,
};

const Divided = packed struct {
    half1: u8,
    quarter3: u4,
    quarter4: u4,
};

test "@bitCast betwwen packed structs" {
    doTheTest();
    comptime doTheTest();
}

fn doTheTest() void {
    assert(@sizeOf(Full) == 2);
    assert(@sizeOf(Divided) == 2);
    var full = Full { .number = 0x1234 };
    var divided = @bitCast(Divided, full);
    switch (builtin.endian) {
        .Big => {
            assert(divided.half1 == 0x12);
            assert(divided.quarter3 == 0x3);
            assert(divided.quarter4 == 0x4);
        },
        .Little => {
            assert(divided.half1 == 0x34);
            assert(divided.quarter3 == 0x2);
            assert(divided.quarter4 == 0x1);
        },
    }
}

const BitField = packed struct {
    a: u3,
    b: u3,
    c: u2,
};

var bfoo = BitField {
    .a = 1,
    .b = 2,
    .c = 3,
};

test "pointer to non-byte-aligned field" {
    const ptr = &bfoo.b;
    assert(ptr.* == 2);

    assert(@ptrToInt(&bfoo.a) == @ptrToInt(&bfoo.b));

    comptime {
        assert(@bitOffsetOf(BitField, "a") == 0);
        assert(@bitOffsetOf(BitField, "b") == 3);
        assert(@bitOffsetOf(BitField, "c") == 6);

        assert(@byteOffsetOf(BitField, "a") == 0);
        assert(@byteOffsetOf(BitField, "b") == 0);
        assert(@byteOffsetOf(BitField, "c") == 0);
    }
}

test "struct name" {
    const Foo = struct {};
    print("variable: {}\n", .{@typeName(Foo)});
    print("anonymous: {}\n", .{@typeName(struct {})});
    print("function: {}\n", .{@typeName(List(i32))});
}

fn List(comptime T: type) type  {
    return struct {
        x: T,
    };
}

test "anonymous struct literal" {
    var pt: Point = .{
        .x = 13,
        .y = 67,
    };
    assert(pt.x == 13);
    assert(pt.y == 67);
}

test "fully anonymous struct" {
    dump(. {
        .int = @as(u32, 1234),
        .float = @as(f64,  12.34),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) void {
    assert(args.int == 1234);
    assert(args.float == 12.34);
    assert(args.b);
    assert(args.s[0] == 'h');
    assert(args.s[1] == 'i');
}