test "access variable after block scope" {
    {
        var x: i32 = 1;
    }
    // x += 1;
}

const std = @import("std");
const assert = std.debug.assert;

test "labeled break from labeled block expression" {
    var y: i32 = 123;

    const x = blk: {
        y += 1;
        break :blk y;
    };

    assert(x == 124);
    assert(y == 124);
}

// const pi = 3.14;

test "inside test block" {
    {
        var pi: i32 = 1234;
    }
}

test "separate scopes" {
    {
        const pi = 3.14;
    }
    {
        var pi: bool = true;
    }
}

test "switch simple" {
    const a: u64 = 10;
    const zz: u64 = 103;

    const b = switch (a) {
        1, 2, 3 => 0,
        5...100 => 1,
        101 => blk: {
            const c: u64 = 5;
            break :blk c * 2 + 1;
        },
        zz => zz,
        comptime blk: {
            const d: u32 = 5;
            const e: u32 = 100;
            break :blk d + e;
        } => 107,
        else => 9,
    };

    assert(b == 1);
}

const os_msg = switch (std.Target.current.os.tag) {
    .linux => "we found a linux user",
    else => "not a linux user",
};

test "switch inside function" {
    switch (std.Target.current.os.tag) {
        .fuchsia => {
            @compileError("fuchsia not supported");
        },
        else => {},
    }
}

test "while basic" {
    var i: usize = 0;
    while (i < 10) {
        i += 1;
    }
    assert(i == 10);
}

test "while loop continue expression" {
    var i: usize = 0;
    while (i < 10) : (i += 1) {}
    assert(i == 10);
}

test "while loop continue expression, more complicated" {
    var i: usize = 1;
    var j: usize = 1;
    while (i * j < 2000) : ({
        i *= 2;
        j *= 3;
    }) {
        const my_ij = i * j;
        assert(my_ij < 2000);
    }
}

test "wile else" {
    assert(rangeHasNumber(0, 10, 5));
    assert(!rangeHasNumber(0, 10, 15));
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "nested break" {
    outer: while (true) {
        while (true) {
            break :outer;
        }
    }
}

test "nested continue" {
    var i: usize = 0;
    outer: while (i < 10) : (i += 1) {
        while (true) {
            continue :outer;
        }
    }
}

test "while null capture" {
    var sum1: u32 = 0;
    numbers_left = 3;
    while (eventuallyNullSequence()) |value| {
        sum1 += value;
    }
    assert(sum1 == 3);

    var sum2: u32 = 0;
    numbers_left = 3;
    while (eventuallyNullSequence()) |value| {
        sum2 += value;
    } else {
        assert(sum2 == 3);
    }
}

var numbers_left: u32 = undefined;
fn eventuallyNullSequence() ?u32 {
    return if (numbers_left == 0) null else blk: {
        numbers_left -= 1;
        break :blk numbers_left;
    };
}

test "while error union capture" {
    var sum1: u32 = 0;
    numbers_left = 3;
    while (eventuallyErrorSequence()) |value| {
        sum1 += value;
    } else |err| {
        assert(err == error.ReachedZero);
    }
}

fn eventuallyErrorSequence() anyerror!u32 {
    return if (numbers_left == 0) error.ReachedZero else blk: {
        numbers_left -= 1;
        break :blk numbers_left;
    };
}

test "inline while loop" {
    comptime var i = 0;
    var sum: usize = 0;
    inline while (i < 3) : (i += 1) {
        const T = switch (i) {
            0 => f32,
            1 => i8,
            2 => bool,
            else => unreachable,
        };
        sum += typeNameLength(T);
    }
    assert(sum == 9);
}

fn typeNameLength(comptime T: type) usize {
    return @typeName(T).len;
}

test "for basics" {
    const items = [_]i32{ 4, 5, 3, 4, 0 };
    var sum: i32 = 0;

    for (items) |value| {
        if (value == 0) {
            continue;
        }
        sum += value;
    }
    assert(sum == 16);

    for (items[0..1]) |value| {
        sum += value;
    }
    assert(sum == 20);

    var sum2: i32 = 0;
    for (items) |value, i| {
        assert(@TypeOf(i) == usize);
        sum2 += @intCast(i32, i);
    }
    assert(sum2 == 10);
}

test "for reference" {
    var items = [_]i32{ 3, 4, 2 };

    for (items) |*value| {
        value.* += 1;
    }

    assert(items[0] == 4);
}

test "for else" {
    var items = [_]?i32{ 3, 4, null, 5 };
    var sum: i32 = 0;
    const result = for (items) |value| {
        if (value != null) {
            sum += value.?;
        }
    } else blk: {
        assert(sum == 12);
        break :blk sum;
    };
    assert(result == 12);
}
