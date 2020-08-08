const std = @import("std");
const assert = std.debug.assert;
const maxInt = std.math.maxInt;
const mem = std.mem;

fn add(a: i8, b: i8) i8 {
    if (a == 0) {
        return b;
    }
    return a + b;
}

export fn sub(a: i8, b: i8) i8 {
    return a - b;
}

extern "kernel32" fn ExitProcess(exit_code: u32) callconv(.Stdcall) noreturn;
extern "c" fn atan(a: f64, b: f64) f64;

fn abort() noreturn {
    @setCold(true);
    while (true) {}
}

fn _start() callconv(.Naked) noreturn {
    abort();
}

inline fn shiftLeftOne(a: u32) u32 {
    return a << 1;
}

pub fn sub2(a: i8, b: i8) i8 {
    return a - b;
}

const call2_op = fn (a: i8, b: i8) i8;
fn do_op(fn_call: call2_op, op1: i8, op2: i8) i8 {
    return fn_call(op1, op2);
}

test "function" {
    assert(do_op(add, 5, 6) == 11);
    assert(do_op(sub2, 5, 6) == -1);
}

comptime {
    assert(@TypeOf(foo) == fn () void);
    assert(@sizeOf(fn () void) == @sizeOf(?fn () void));
}

fn foo() void {}

fn addFortyTwo(x: anytype) @TypeOf(x) {
    return x + 42;
}

test "fn type inference" {
    assert(@TypeOf(addFortyTwo(1)) == comptime_int);
}

test "fn reflection" {
    assert(@TypeOf(assert).ReturnType == void);
    assert(@TypeOf(assert).is_var_args == false);
}

const FileOpenError = error{
    AssessDenied1,
    OutOfMemory,
    FileNotFound1,
};

const AllocationError = error{OutOfMemory};

test "coerce subset to superset" {
    const err = efoo(AllocationError.OutOfMemory);
    assert(err == FileOpenError.OutOfMemory);
}

fn efoo(err: AllocationError) FileOpenError {
    return err;
}

const specErr = error.FileNotFound;

pub fn parseU64(buf: []const u8, radix: u8) !u64 {
    var x: u64 = 0;
    for (buf) |c| {
        const digit = charToDigit(c);
        if (digit >= radix) {
            return error.InvalidChar;
        }
        if (@mulWithOverflow(u64, x, radix, &x)) {
            return error.Overflow;
        }
        if (@addWithOverflow(u64, x, digit, &x)) {
            return error.Overflow;
        }
    }
    return x;
}

fn charToDigit(c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'A'...'Z' => c - 'A' + 10,
        'a'...'z' => c - 'a' + 10,
        else => maxInt(u8),
    };
}

test "parse u64" {
    const result = try parseU64("1234", 10);
    assert(result == 1234);
}

fn doAthing(std: []u8) void {
    if (parseU64(str, 10)) |value| {
        // num
    } else |err| switch (err) {
        _ => unreachable,
    }
}

test "merge error union" {
    const A = error{
        a,
        b,
        c,
    };
    const B = error{b};
    const C = A || B;
    var err: C!u32 = C.a;
}

test "cast pointers" {
    const window_name = [1][*]const u8{"window name"};
    const x: [*]const ?[*]const u8 = &window_name;
    assert(mem.eql(u8, mem.spanZ(@ptrCast([*:0]const u8, x[0].?)), "window name"));
}

test "integer widening" {
    var a: u8 = 250;
    var b: u16 = a;
    var c: u32 = b;
    var d: u64 = c;
    var e: u64 = d;
    var f: i128 = e;
    assert(f == a);
}

test "[N]T to []const T" {
    var x1: []const u8 = "hello";
    var x2: anyerror![]const u8 = &[5]u8{ 'h', 'e', 'l', 'l', 111 };
    assert(mem.eql(u8, x1, try x2));
}

test "sip" {
    var ori: [5]u8 = "hello".*;
    const x: ?[*]u8 = &ori;
    assert(x.?[0] == 'h');
    var ori1: u8 = 123;
    const y: *[1]u8 = &ori1;
    const z: [*]u8 = y;
    assert(z[0] == 123);
}

test "coerce to wrapped" {
    const x: anyerror!?u8 = 123;
    assert((try x).? == 123);
}

test "coercion to error unions" {
    const x: anyerror!i32 = error.Failure;
    std.testing.expectError(error.Failure, x);
}

test "clittsowvicktf" {
    const x: u64 = 255;
    const y: u8 = x;
    assert(y == 255);
}

const E = enum {
    One,
    Two,
    Three,
};

const U = union(E) {
    One: i32,
    Two: f32,
    Three,
};

test "between u&e" {
    var u = U{ .Two = 12.34 };
    var a: E = u;
    assert(a == E.Two);

    const three = E.Three;
    var another_u: U = three;
    assert(another_u == E.Three);
}

test "coercion of zero bit types" {
    var x: void = {};
    var y: *void = x;
    // var z: void = y;
}

test "peer resolve int widening" {
    var a: i8 = 12;
    var b: i16 = 34;
    var c = a + b;
    assert(@TypeOf(c) == i16);
}

test "different size array to const slice" {
    assert(mem.eql(u8, boolToStr(true), "true"));
    comptime assert(mem.eql(u8, boolToStr(true), "true"));
}

fn boolToStr(b: bool) []const u8 {
    return if (b) "true" else @as([]const u8, "false");
}

test "peer type resolution: *const T and ?*T" {
    const a = @intToPtr(*const usize, 0x123456780);
    const b = @intToPtr(?*usize, 0x123456780);
    assert(a == b);
}

export fn entry() void {
    var x: void = {};
    var y: void = {};
    x = y;
}

test "turn HashMap into a set with void" {
    var map = std.AutoHashMap(i32, void).init(std.testing.allocator);
    defer map.deinit();

    try map.put(1, {});
    try map.put(2, {});

    assert(map.contains(2));
    assert(!map.contains(3));

    _ = map.remove(2);
    assert(!map.contains(2));
}
