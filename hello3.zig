const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;

const Type = enum {
    Ok,
    NotOk,
};

const Value = enum(u2) {
    Zero,
    One,
    Two,
};

test "enum ordinal value" {
    const c = Type.Ok;
    assert(@enumToInt(Value.Zero) == 0);
    assert(@enumToInt(Value.One) == 1);
    assert(@enumToInt(Value.Two) == 2);
}

const Value2 = enum(u32) {
    Hundred = 100,
    Thousand = 1000,
    Million = 1000000,
};

test "set enum ordinal value" {
    assert(@enumToInt(Value2.Hundred) == 100);
    assert(@enumToInt(Value2.Thousand) == 1000);
    assert(@enumToInt(Value2.Million) == 1000000);
}

const Suit = enum {
    Clubs,
    Spades,
    Diamonds,
    Hearts,

    pub fn isClubs(self: Suit) bool {
        return self == Suit.Clubs;
    }
};

test "enum method" {
    const p = Suit.Spades;
    assert(!p.isClubs());
}

const Foo = enum {
    String,
    Number,
    None,
};

test "enum variant switch" {
    const p = Foo.Number;
    const what_is_it = switch (p) {
        Foo.String => "this is a string",
        Foo.Number => "this is a number",
        Foo.None => "this is a none",
    };
    assert(mem.eql(u8, what_is_it, "this is a number"));
}

const Small = enum {
    One,
    Two,
    Three,
    Four,
};

test "@TagType" {
    assert(@TagType(Small) == u2);
}

test "@typeInfo" {
    assert(@typeInfo(Small).Enum.fields.len == 4);
    assert(mem.eql(u8, @typeInfo(Small).Enum.fields[1].name, "Two"));
}

test "@tagName" {
    assert(mem.eql(u8, @tagName(Small.Three), "Three"));
}

const EFoo = extern enum { A, B, C };
export fn entry(foo: EFoo) void {}

test "packed enum" {
    const Number = packed enum(u8) {
        One,
        Two,
        Three,
    };
    assert(@sizeOf(Number) == @sizeOf(u8));
}

const Color = enum {
    Auto,
    Off,
    On,
};

test "enum literals" {
    const color1: Color = .Auto;
    const color2 = Color.Auto;
    assert(color1 == color2);
}

test "switch using enum literals" {
    const color = Color.On;
    const result = switch (color) {
        .Auto => false,
        .On => true,
        .Off => false,
    };
    assert(result);
}

test "switch on non-exhaustive enum" {
    const Number = enum(u8) {
        One,
        Two,
        Three,
        _,
    };
    const number = Number.One;
    const result = switch (number) {
        .One => true,
        .Two, .Three => false,
        _ => false,
    };
    assert(result);
    const is_one = switch (number) {
        .One => true,
        else => false,
    };
    assert(is_one);
}

const Payload = union {
    Int: i64,
    Float: f64,
    Bool: bool,
};

test "simple union" {
    var payload = Payload{ .Int = 1234 };
    payload = Payload{ .Float = 12.34 };
}

const ComplexTypeTag = enum {
    Ok,
    NotOk,
};

const ComplexType = union(ComplexTypeTag) {
    Ok: u8,
    NotOk: void,
};

test "switch on tagged union" {
    const c = ComplexType{ .Ok = 42 };
    assert(@as(ComplexTypeTag, c) == ComplexTypeTag.Ok);

    switch (c) {
        ComplexTypeTag.Ok => |value| assert(value == 42),
        ComplexTypeTag.NotOk => unreachable,
    }
}

test "@TagType" {
    assert(@TagType(ComplexType) == ComplexTypeTag);
}

test "coerce to enum" {
    const c1 = ComplexType{ .Ok = 42 };
    const c2 = ComplexType.NotOk;

    assert(c1 == .Ok);
    assert(c2 == .NotOk);
}

test "modify tagged union in switch" {
    var c = ComplexType{ .Ok = 42 };
    assert(@as(ComplexTypeTag, c) == ComplexTypeTag.Ok);

    switch (c) {
        ComplexTypeTag.Ok => |*value| value.* += 1,
        ComplexTypeTag.NotOk => unreachable,
    }

    assert(c.Ok == 43);
}

const Variant = union(enum) {
    Int: i32,
    Bool: bool,
    None,

    fn truthy(self: Variant) bool {
        return switch (self) {
            Variant.Int => |x_int| x_int != 0,
            Variant.Bool => |x_bool| x_bool,
            Variant.None => false,
        };
    }
};

test "union method" {
    var v1 = Variant{ .Int = 1 };
    var v2 = Variant{ .Bool = false };

    assert(v1.truthy());
    assert(!v2.truthy());
}

const Small2 = union(enum) {
    A: i32,
    B: bool,
    C: u8,
};

test "@tagName" {
    assert(mem.eql(u8, @tagName(Small2.C), "C"));
}

const anumber = union {
    int: i32,
    float: f64,
};

test "anonymous union literal syntax" {
    var i: anumber = .{ .int = 42 };
    var f = makeNumber();
    assert(i.int == 42);
    assert(f.float == 12.34);
}

fn makeNumber() anumber {
    return .{ .float = 12.34 };
}
