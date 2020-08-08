//! this is a top-level doc comment

const std = @import("std");
const print = @import("std").debug.print;
const assert = @import("std").debug.assert;
const mem = @import("std").mem;

test "HelloWorld" {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, {}!\n", .{"world"});
}

test "HelloAgain" {
    print("Hello, world!\n", .{});
}

test "Comments" {
    // Comments start with "//"
    const x = true;
    assert(x);
}

test "values" {
    const one_plus_one: i32 = 1 + 1;
    const seven_div_three: f32 = 7.0 / 3.0;
    var optional_value: ?[]const u8 = null;
    print("1+1={}, 7/3={}, opt={}\n", .{ one_plus_one, seven_div_three, optional_value });
    optional_value = "Hi";
    print("opt name: {}, value: {}\n", .{ @typeName(@TypeOf(optional_value)), optional_value });
    var error_union: anyerror!i32 = error.ArgNotFound;
    print("{}\n", .{error_union});
}

test "string literals" {
    const bytes = "Hello";
    assert(@TypeOf(bytes) == *const [5:0]u8);
    assert(bytes.len == 5);
    assert(mem.eql(u8, "hello", "h\x65llo"));
    const ml =
        \\
        \\ line 1
        \\ line 2
        \\ line 3
    ;
    print("{}\n", .{ml});
}

test "assign" {
    var y: i32 = 100;
    y += 1;
    assert(y == 101);
    var x: i32 = undefined;
    x = 1;
    assert(x == 1);
}

var gy: i32 = add(10, gx);
const gx: i32 = add(12, 34);

test "global variables" {
    assert(gx == 46);
    assert(gy == 56);
}

fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "namespaced global variable" {
    assert(ngfoo() == 1235);
    assert(ngfoo() == 1236);
}

fn ngfoo() i32 {
    const S = struct {
        var x: i32 = 1234;
    };
    S.x += 1;
    return S.x;
}

threadlocal var tlx: i32 = 1234;

test "thread local storage" {
    const thread1 = try std.Thread.spawn({}, testTls);
    const thread2 = try std.Thread.spawn({}, testTls);
    testTls({});
    thread1.wait();
    thread2.wait();
}

fn testTls(context: void) void {
    assert(tlx == 1234);
    tlx += 1;
    assert(tlx == 1235);
}

test "comptime vars" {
    var x: i32 = 1;
    comptime var y: i32 = 1;
    x += 1;
    y += 1;
    if (y != 2) {
        @compileError("wrong y value");
    }
}

const dec_int = 98222;
const hex_int = 0xff;
const oct_int = 0o755;
const bin_int = 0b1100;

const one_billion = 1_000_000_000;

const inf = std.math.inf(f32);
const neg_inf = -std.math.inf(f64);
const nan = std.math.nan(f128);

const builtin = std.builtin;
const big = @as(f64, 1 << 40);

export fn foo_strict(x: f64) f64 {
    return x + big - big;
}

export fn foo_optimized(x: f64) f64 {
    @setFloatMode(.Optimized);
    return x + big - big;
}
