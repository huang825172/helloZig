// Seems not working

const std = @import("std");
const expect = std.testing.expect;

test "vector of pointers" {
    var array0: [10]i32 = undefined;
    var array1: [10]i32 = undefined;
    var array2: [10]i32 = undefined;
    var array3: [10]i32 = undefined;

    const vector_of_ptrs: @Vector(4, [*]i32) =
        [_][*]i32 { &array0, &array1, &array2, &array3 };
    const index: @Vector(4, u32) = [_]u32 {5, 2, 3, 6};

    vector_of_ptrs[index] = [_]i32{11, 22, 33, 44};

    expect(array0[5] == 11);
    expect(array1[2] == 22);
    expect(array2[3] == 33);
    expect(array3[6] == 44);
}