usingnamespace @import("std");

test "using std namespace" {
    debug.assert(true);
}

// pub usingnamespace @cImport({
//     @cInclude("epoxy/gl.h");
//     @cInclude("GLFW/glfw3.h");
//     @cDefine("STBI_ONLY_PNG", "");
//     @cDefine("STBI_NO_STDIO", "");
//     @cInclude("stb_image.h");
// })

fn max(comptime T: type, a: T, b: T) T {
    if (T == bool) {
        return a or b;
    }
    return if (a > b) a else b;
}

test "compare bools" {
    debug.assert(max(bool, false, true) == true);
}

fn fibonacci(index: u32) u32 {
    if (index < 2) return index;
    return fibonacci(index - 1) + fibonacci(index - 2);
}

test "fibonacci" {
    debug.assert(fibonacci(7) == 13);
    comptime {
        debug.assert(fibonacci(7) == 13);
    }
}

var x: i32 = undefined;

fn func1() void {
    x += 1;
    suspend;
    x += 1;
}

test "suspend with no resume" {
    x = 1;
    var frame = async func1();
    debug.assert(x == 2);
}

var the_frame: anyframe = undefined;
var result = false;

test "async function suspend with block" {
    _ = async testSuspendBlock();
    debug.assert(!result);
    resume the_frame;
    debug.assert(result);
}

fn testSuspendBlock() void {
    suspend {
        comptime debug.assert(@TypeOf(@frame()) == *@Frame(testSuspendBlock));
        the_frame = @frame();
    }
    result = true;
}

test "resume from suspend" {
    var my_result: i32 = 1;
    _ = async testResumeFromSuspend(&my_result);
    debug.assert(my_result == 2);
}

fn testResumeFromSuspend(my_result: *i32) void {
    suspend {
        resume @frame();
    }
    my_result.* += 1;
    suspend;
    my_result.* += 1;
}

test "async and await" {
    _ = async amain();
}

fn amain() void {
    var frame = async func();
    comptime debug.assert(@TypeOf(frame) == @Frame(func));

    const ptr: anyframe->void = &frame;
    const any_ptr: anyframe = ptr;

    resume any_ptr;
    await ptr;
}

fn func() void {
    suspend;
}

const assert = debug.assert;

var the_frame1: anyframe = undefined;
var final_result: i32 = 0;
var seq_points = [_]u8{0} ** "abcdefghi".len;
var seq_index: usize = 0;

test "async function await" {
    seq('a');
    _ = async amain1();
    seq('f');
    resume the_frame1;
    seq('i');
    assert(final_result == 1234);
    assert(mem.eql(u8, &seq_points, "abcdefghi"));
}

fn amain1() void {
    seq('b');
    var f = async another();
    seq('e');
    final_result = await f;
    seq('h');
}

fn another() i32 {
    seq('c');
    suspend {
        seq('d');
        the_frame1 = @frame();
    }
    seq('g');
    return 1234;
}

fn seq(ch: u8) void {
    seq_points[seq_index] = ch;
    seq_index += 1;
}