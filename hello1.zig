const print = @import("std").debug.print;

extern fn foo_strict(x: f64) f64;
extern fn foo_optimized(x: f64) f64;

pub fn main() void {
    const x = 0.001;
    print("Optimized = {}\n", .{foo_optimized(x)});
    print("Strict = {}\n", .{foo_strict(x)});
}

const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

test "operator" {
    assert(@as(u32, 0) -% 1 == std.math.maxInt(u32));

    const value: ?u32 = null;
    const unwrapped = value orelse 1234;
    assert(unwrapped == 1234);

    const value1: anyerror!u32 = error.Broken;
    const unwrapped1 = value1 catch 1234;
    assert(unwrapped1 == 1234);

    const a1 = [_]u32{ 1, 2 };
    const a2 = [_]u32{ 3, 4 };
    const together = a1 ++ a2;
    assert(mem.eql(u32, &together, &[_]u32{ 1, 2, 3, 4 }));

    const x: u32 = 1234;
    const ptr = &x;
    assert(ptr.* == 1234);

    // ?
    // const A = error{One};
    // const B = error{Two};
    // assert((A || B) == error{One, Two});
}

const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const same_message = "hello";

comptime {
    assert(message.len == 5);
    assert(mem.eql(u8, &message, same_message));
}

test "iterate over an array" {
    var sum: usize = 0;
    for (message) |byte| {
        sum += byte;
    }
    assert(sum == 'h' + 'e' + 'l' * 2 + 'o');
}

var some_integers: [100]i32 = undefined;

test "modify an array" {
    for (some_integers) |*item, i| {
        item.* = @intCast(i32, i);
    }
    assert(some_integers[10] == 10);
    assert(some_integers[99] == 99);
}

const all_zero = [_]u16{0} ** 10;

comptime {
    assert(all_zero.len == 10);
    assert(all_zero[5] == 0);
}

var fancy_array = init: {
    var initial_val: [10]Point = undefined;
    for (initial_val) |*pt, i| {
        pt.* = Point{
            .x = @intCast(i32, i),
            .y = @intCast(i32, i) * 2,
        };
    }
    break :init initial_val;
};
const Point = struct {
    x: i32,
    y: i32,
};

test "compile-time array initalization" {
    assert(fancy_array[4].x == 4);
    assert(fancy_array[4].y == 8);
}

var more_points = [_]Point{makePoint(3)} ** 10;
fn makePoint(x: i32) Point {
    return Point{
        .x = x,
        .y = x * 2,
    };
}

test "array initialization with function calls" {
    assert(more_points[4].x == 3);
    assert(more_points[4].y == 6);
    assert(more_points.len == 10);
}

test "anonymous list literal syntax" {
    var array: [4]u8 = .{ 11, 22, 33, 44 };
    assert(array[0] == 11);
    assert(array[1] == 22);
}

test "fully anonymous list literal" {
    dump(.{ @as(u32, 1234), @as(f64, 12.34), true, "hi" });
}

fn dump(args: anytype) void {
    assert(args.@"0" == 1234);
    assert(args.@"1" == 12.34);
    assert(args.@"2");
    assert(args.@"3"[0] == 'h');
    assert(args.@"3"[1] == 'i');
}

const mat4x4 = [4][4]f32{
    [_]f32{ 1.0, 0.0, 0.0, 0.0 },
    [_]f32{ 0.0, 1.0, 0.0, 0.0 },
    [_]f32{ 0.0, 0.0, 1.0, 0.0 },
    [_]f32{ 0.0, 0.0, 0.0, 1.0 },
};

test "multidimensional arrays" {
    assert(mat4x4[1][1] == 1.0);
    for (mat4x4) |row, row_index| {
        for (row) |cell, column_index| {
            if (row_index == column_index) {
                assert(cell == 1.0);
            }
        }
    }
}

test "null terminated array" {
    const array = [_:0]u8{ 1, 2, 3, 4 };
    assert(@TypeOf(array) == [4:0]u8);
    assert(array.len == 4);
    assert(array[4] == 0);
}

// Vectors and SIMD

test "address of syntax" {
    const x: i32 = 1234;
    const x_ptr = &x;
    assert(x_ptr.* == 1234);

    assert(@TypeOf(x_ptr) == *const i32);

    var y: i32 = 5678;
    const y_ptr = &y;
    assert(@TypeOf(y_ptr) == *i32);
    y_ptr.* += 1;
    assert(y_ptr.* == 5679);
}

test "pointer array access" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    const ptr = &array[2];
    assert(@TypeOf(ptr) == *u8);

    assert(array[2] == 3);
    ptr.* += 1;
    assert(array[2] == 4);
}

test "pointer slicing" {
    var array = [_]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 };
    const slice = array[2..4];
    assert(slice.len == 2);

    assert(array[3] == 4);
    slice[1] += 1;
    assert(array[3] == 5);
}

test "comptime pointers" {
    comptime {
        var x: i32 = 1;
        const ptr = &x;
        ptr.* += 1;
        x += 1;
        assert(ptr.* == 3);
    }
}

test "@ptrToInt and @intToPtr" {
    const ptr = @intToPtr(*i32, 0xdeadbee0);
    const addr = @ptrToInt(ptr);
    assert(@TypeOf(addr) == usize);
    assert(addr == 0xdeadbee0);
}

test "volatile" {
    const mmio_ptr = @intToPtr(*volatile u8, 0x12345678);
    assert(@TypeOf(mmio_ptr) == *volatile u8);
}

test "pointer casting" {
    const bytes align(@alignOf(u32)) = [_]u8{ 0x12, 0x12, 0x12, 0x12 };
    const u32_ptr = @ptrCast(*const u32, &bytes);
    assert(u32_ptr.* == 0x12121212);

    const u32_value = std.mem.bytesAsSlice(u32, bytes[0..])[0];
    assert(u32_value == 0x12121212);
}

test "pointer child type" {
    assert((*u32).Child == u32);
}

test "variable alignment" {
    var x: i32 = 1234;
    const align_of_i32 = @alignOf(@TypeOf(x));
    assert(@TypeOf(&x) == *i32);
    assert(*i32 == *align(align_of_i32) i32);
    if (std.Target.current.cpu.arch == .x86_64) {
        assert((*i32).alignment == 4);
    }
}

var afoo: u8 align(4) = 100;

test "global variable alignment" {
    assert(@TypeOf(&afoo).alignment == 4);
    assert(@TypeOf(&afoo) == *align(4) u8);
    const as_pointer_to_array: *[1]u8 = &afoo;
    const as_slice: []u8 = as_pointer_to_array;
    assert(@TypeOf(as_slice) == []align(4) u8);
}

fn derp() align(@sizeOf(usize) * 2) i32 {
    return 1234;
}
fn noop1() align(1) void {}
fn noop4() align(4) void {}

test "function alignment" {
    assert(derp() == 1234);
    assert(@TypeOf(noop1) == fn () align(1) void);
    assert(@TypeOf(noop4) == fn () align(4) void);
    noop1();
    noop4();
}

test "pointer alignment safety" {
    var array align(4) = [_]u32{ 0x11111111, 0x11111111 };
    const bytes = std.mem.sliceAsBytes(array[0..]);
    // assert(pafoo(bytes) == 0x11111111);
}

fn pafoo(bytes: []u8) u32 {
    const slice4 = bytes[1..5];
    const int_slice = std.mem.bytesAsSlice(u32, @alignCast(4, slice4));
    return int_slice[0];
}

test "allowzero" {
    var zero: usize = 0;
    var ptr = @intToPtr(*allowzero i32, zero);
    assert(@ptrToInt(ptr) == 0);
}

pub extern "c" fn printf(format: [*:0]const u8, ...) c_int;

test "sentinel Terminated Pointers" {
    _ = printf("Hello, world!\n");
}