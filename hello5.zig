const std = @import("std");
const assert = std.debug.assert;
const print = std.debug.print;

test "if expression" {
    const a: u32 = 5;
    const b: u32 = 4;
    const result = if (a != b) 47 else 3089;
    assert(result == 47);
}

test "if optional" {
    var a: ?u32 = 0;
    if (a) |value| {
        assert(value == 0);
    } else {
        unreachable;
    }

    if (a) |*value| {
        value.* = 1;
    }
    assert(a.? == 1);

    const b: ?u32 = null;
    if (b) |value| {
        unreachable;
    } else {
        assert(true);
    }

    if (b == null) {
        assert(true);
    }
}

test "if error union" {
    const a: anyerror!u32 = 0;
    if (a) |value| {
        assert(value == 0);
    } else |err| {
        unreachable;
    }

    if (a) |value| {
        assert(value == 0);
    } else |_| {}

    const b: anyerror!u32 = error.BadValue;
    if (b) |_| {} else |err| {
        assert(err == error.BadValue);
    }

    const c: anyerror!?u32 = null;
    if (c) |value| {
        if (value) |val| {
            unreachable;
        } else {
            assert(true);
        }
    } else |err| {
        unreachable;
    }

    var d: anyerror!?u32 = 3;
    if (d) |*value| {
        if (value.*) |*val| {
            val.* = 9;
        }
    } else |err| {
        unreachable;
    }
    if (d) |value| {
        assert(value.? == 9);
    } else |_| {}
}

fn deferExample() usize {
    var a: usize = 1;
    {
        defer a = 2;
        a = 1;
    }
    assert(a == 2);

    a = 5;
    return a;
}

test "defer basics" {
    assert(deferExample() == 5);
}

fn deferUnwindExample() void {
    print("\n", .{});

    defer {
        print("1 ", .{});
    }
    defer {
        print("2 ", .{});
    }
    if (false) {
        defer {
            print("3 ", .{});
        }
    }
}

test "defer unwinding" {
    deferUnwindExample();
    // No output?
}

fn deferErrorExample(is_error: bool) !void {
    print("\nStart of function\n", .{});
    defer {
        print("\nEnd of function\n", .{});
    }
    errdefer {
        print("encountered an error!\n", .{});
    }
    if (is_error) {
        return error.DeferError;
    }
}

test "errdefer unwinding" {
    deferErrorExample(false) catch {};
    deferErrorExample(true) catch {};
}

test "type of unreachable" {
    comptime {
        // assert(@TypeOf(unreachable) == noreturn);
    }
}

fn foo(condition: bool, b: u32) void {
    const a = if (condition) b else return;
    @panic("Do something with a");
}

test "noreturn" {
    foo(false, 1);
}

pub extern "kernel32" fn ExitProcess(exit_code: c_uint) callconv(.Stdcall) noreturn;

test "foo" {
    const value = bar() catch ExitProcess(1);
    assert(value == 1234);
}

fn bar() anyerror!u32 {
    return 1234;
}
