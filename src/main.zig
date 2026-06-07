const std = @import("std");

const mecha = @import("mecha");

const Io = std.Io;

const zig_sgf = @import("zig_sgf");

const parseIgnoreWhitespace = mecha.many(mecha.ascii.whitespace, .{}).discard();

const parseCValueType = mecha.oneOf(.{
    // mecha.combine(.{
    //     mecha.ascii.char('\\'),
    //     mecha.ascii.char(']'),
    // }),
    mecha.ascii.not(mecha.ascii.char(']')),
});

const parsePropValue = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char('[').discard(),
    mecha.asStr(mecha.many(parseCValueType, .{})),
    mecha.ascii.char(']').discard(),
    parseIgnoreWhitespace,
});

const parsePropIdent = mecha.combine(.{
    mecha.asStr(mecha.many(mecha.ascii.upper, .{ .min = 1 })),
});

const rawPropertyStruct = struct {
    ident: []const u8,
    values: [][]const u8,
};

const parseProperty = mecha.combine(.{
    parseIgnoreWhitespace,
    parsePropIdent,
    parseIgnoreWhitespace,
    mecha.many(parsePropValue, .{ .min = 1 }),
    parseIgnoreWhitespace,
});

fn parsedPropertyToStruct(result: struct { []const u8, [][]const u8 }) rawPropertyStruct {
    return .{
        .ident = result[0],
        .values = result[1],
    };
}

const parseNode = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char(';').discard(),
    parseIgnoreWhitespace,
    // mecha.many(parseProperty, .{}),
    mecha.many(parseProperty.map(parsedPropertyToStruct), .{}),
    parseIgnoreWhitespace,
});

const rawNodeStruct = struct {
    properties: []rawPropertyStruct,
};
fn parsedNodeToStruct(result: []rawPropertyStruct) rawNodeStruct {
    return .{
        .properties = result,
    };
}

const parseSequence = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.many(parseNode.map(parsedNodeToStruct), .{ .min = 1 }),
    parseIgnoreWhitespace,
});

const rawSequenceStruct = struct {
    nodes: []rawNodeStruct,
};
fn parsedSequenceToStruct(result: []rawNodeStruct) rawSequenceStruct {
    return .{
        .nodes = result,
    };
}

const parseGameTree = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char('(').discard(),
    parseIgnoreWhitespace,
    parseSequence.map(parsedSequenceToStruct),
    parseIgnoreWhitespace,
    mecha.many(mecha.ref(recursiveParseGameTree), .{}),
    parseIgnoreWhitespace,
    mecha.ascii.char(')').discard(),
    parseIgnoreWhitespace,
}).map(parsedGameTreeToStruct);
fn recursiveParseGameTree() mecha.Parser(rawGameTreeStruct) {
    return parseGameTree;
}

fn debugPrintNSpaces(num: u32) void {
    for (0..num) |_| {
        std.debug.print(" ", .{});
    }
}

const rawGameTreeStruct = struct {
    sequence: rawSequenceStruct,
    sub_game_trees: []rawGameTreeStruct,

    fn pretty_print(self: rawGameTreeStruct, extras: struct { depth: u32 = 0 }) void {
        debugPrintNSpaces(extras.depth * 2);
        std.debug.print("rawGameTreeStruct:\n", .{});
        for (self.sequence.nodes) |node| {
            debugPrintNSpaces(extras.depth * 2);
            std.debug.print("  Node:\n", .{});
            for (node.properties) |property| {
                debugPrintNSpaces(extras.depth * 2);
                std.debug.print("    {s} =", .{property.ident});
                for (property.values) |value| {
                    std.debug.print(" \"{s}\"", .{value});
                }
                std.debug.print("\n", .{});
            }
        }

        for (self.sub_game_trees) |sub_game_tree| {
            sub_game_tree.pretty_print(.{ .depth = extras.depth + 1 });
        }
    }
};
fn parsedGameTreeToStruct(result: struct { rawSequenceStruct, []rawGameTreeStruct }) rawGameTreeStruct {
    return .{
        .sequence = result[0],
        .sub_game_trees = result[1],
    };
}

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const allocator: std.mem.Allocator = init.arena.allocator();

    const io = init.io;
    const contents = try std.Io.Dir.readFileAlloc(
        try std.Io.Dir.cwd().openDir(io, "example-sgfs", .{}),
        io,
        // "3-3_invasion_variations.sgf",
        "Andrius-blit-2020-01-21.sgf",
        allocator,
        .unlimited,
    );
    defer allocator.free(contents);

    const parsedSgf = (try parseGameTree.parse(allocator, contents)).value.ok;
    // std.debug.print("{any}\n", .{parsedSgf});

    parsedSgf.pretty_print(.{});
}
