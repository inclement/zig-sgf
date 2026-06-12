const std = @import("std");
const mecha = @import("mecha");

pub const RawPropertyStruct = struct {
    ident: []const u8,
    values: [][]u8,
    fn fromParsedProperty(result: struct { []const u8, [][]u8 }) RawPropertyStruct {
        return .{
            .ident = result[0],
            .values = result[1],
        };
    }

    pub fn deinit(this: *const RawPropertyStruct, allocator: std.mem.Allocator) void {
        allocator.free(this.ident);
        for (this.values) |item| {
            allocator.free(item);
        }
        allocator.free(this.values);
        // _ = this;
        // _ = allocator;
    }
};

pub const RawNodeStruct = struct {
    properties: []RawPropertyStruct,
    fn fromParsedNode(result: []RawPropertyStruct) RawNodeStruct {
        return .{
            .properties = result,
        };
    }

    pub fn deinit(this: *const RawNodeStruct, allocator: std.mem.Allocator) void {
        for (this.properties) |property| {
            property.deinit(allocator);
        }
        allocator.free(this.properties);
    }
};

pub const RawSequenceStruct = struct {
    nodes: []RawNodeStruct,
    fn fromParsedSequence(result: []RawNodeStruct) RawSequenceStruct {
        return .{
            .nodes = result,
        };
    }

    pub fn deinit(this: *const RawSequenceStruct, allocator: std.mem.Allocator) void {
        for (this.nodes) |node| {
            node.deinit(allocator);
        }
        allocator.free(this.nodes);
    }
};

pub const RawGameTreeStruct = struct {
    sequence: RawSequenceStruct,
    sub_game_trees: []RawGameTreeStruct,
    fn fromParsedGameTree(result: struct { RawSequenceStruct, []RawGameTreeStruct }) RawGameTreeStruct {
        return .{
            .sequence = result[0],
            .sub_game_trees = result[1],
        };
    }

    pub fn deinit(this: *const RawGameTreeStruct, allocator: std.mem.Allocator) void {
        this.sequence.deinit(allocator);

        for (this.sub_game_trees) |game_tree| {
            game_tree.deinit(allocator);
        }
        allocator.free(this.sub_game_trees);
    }

    pub fn pretty_print(self: RawGameTreeStruct, extras: struct { depth: u32 = 0 }) void {
        // TODO this is a mess
        debugPrintNSpaces(extras.depth * 2);
        std.debug.print("RawGameTreeStruct:\n", .{});
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

pub const RawCollectionStruct = struct {
    game_trees: []RawGameTreeStruct,
    fn fromParsedCollection(result: []RawGameTreeStruct) RawCollectionStruct {
        return .{
            .game_trees = result,
        };
    }
    pub fn deinit(this: *const RawCollectionStruct, allocator: std.mem.Allocator) void {
        for (this.game_trees) |game_tree| {
            game_tree.deinit(allocator);
        }

        allocator.free(this.game_trees);
    }
};

const parseIgnoreWhitespace = mecha.many(mecha.ascii.whitespace.discard(), .{}).discard();
// I think this could work with the peek functionality in https://github.com/Hejsil/mecha/pull/80 ?
// const parseCValueType = mecha.oneOf(.{
//     // TODO: allow escaped close bracket
//     // mecha.combine(.{
//     //     mecha.ascii.char('\\'),
//     //     mecha.ascii.char(']'),
//     // }),
//     mecha.ascii.not(mecha.ascii.char(']')),
// });
const parseCValueType = mecha.ascii.not(mecha.ascii.char(']'));
const parsePropValue = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char('[').discard(),
    // mecha.asStr(mecha.many(parseCValueType, .{})),
    mecha.many(parseCValueType, .{}),
    mecha.ascii.char(']').discard(),
    parseIgnoreWhitespace,
});
const parsePropIdent = mecha.combine(.{
    // mecha.asStr(mecha.many(mecha.ascii.upper, .{ .min = 1 })),
    mecha.many(mecha.ascii.upper, .{ .min = 1 }),
});
const parseProperty = mecha.combine(.{
    parseIgnoreWhitespace,
    parsePropIdent,
    parseIgnoreWhitespace,
    mecha.many(parsePropValue, .{ .min = 1 }),
    parseIgnoreWhitespace,
}).map(RawPropertyStruct.fromParsedProperty);
const parseNode = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char(';').discard(),
    parseIgnoreWhitespace,
    mecha.many(parseProperty, .{}),
    parseIgnoreWhitespace,
}).map(RawNodeStruct.fromParsedNode);
const parseSequence = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.many(parseNode, .{ .min = 1 }),
    parseIgnoreWhitespace,
}).map(RawSequenceStruct.fromParsedSequence);
const parseGameTree = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char('(').discard(),
    parseIgnoreWhitespace,
    parseSequence,
    parseIgnoreWhitespace,
    mecha.many(mecha.ref(recursiveParseGameTree), .{}),
    parseIgnoreWhitespace,
    mecha.ascii.char(')').discard(),
    parseIgnoreWhitespace,
}).map(RawGameTreeStruct.fromParsedGameTree);
fn recursiveParseGameTree() mecha.Parser(RawGameTreeStruct) {
    return parseGameTree;
}
const parseCollection = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.many(parseGameTree, .{ .min = 1 }),
    parseIgnoreWhitespace,
}).map(RawCollectionStruct.fromParsedCollection);

fn debugPrintNSpaces(num: u32) void {
    for (0..num) |_| {
        std.debug.print(" ", .{});
    }
}

pub fn parseSgfToRawCollection(allocator: std.mem.Allocator, text: []const u8) !RawCollectionStruct {
    const result: mecha.Result(RawCollectionStruct) = try parseCollection.parse(allocator, text);
    return result.value.ok;
}

pub fn parseSgfToSingleGameTree(allocator: std.mem.Allocator, text: []const u8) !RawGameTreeStruct {
    const result: mecha.Result(RawGameTreeStruct) = try parseGameTree.parse(allocator, text);
    return result.value.ok;
}

test "basic parse" {
    const collection: RawCollectionStruct = try parseSgfToRawCollection(std.testing.allocator, "(;B[ab] ;Q[cd])");
    defer collection.deinit(std.testing.allocator);
    try std.testing.expectEqual(collection.game_trees.len, 1);
}

test "multiple game trees" {
    const collection = try parseSgfToRawCollection(std.testing.allocator, "(;B[ab])(;W[cd])");
    defer collection.deinit(std.testing.allocator);
    try std.testing.expectEqual(collection.game_trees.len, 2);
}

test "complex parse" {
    const branched_sgf_string: []const u8 =
        \\(;B[de]
        \\FF[4]CA[UTF-8]AP[CGoban:3]ST[2]
        \\RU[AGA]SZ[19]KM[7.50]
        \\PW[White]PB[Black]
        \\(;B[qe]
        \\(;W[pb]
        \\;B[nc])
        \\(;W[rg]
        \\(;B[sc]
        \\;W[rj])
        \\(;B[sd]
        \\;B[qk])))
        \\(;B[qf]
        \\(;W[rf]
        \\(;B[rg]
        \\(;B[qg]
        \\;B[nc])
        \\(;B[pg]
        \\;B[nc]))
        \\(;B[pe]
        \\;W[rg]))
        \\(;W[qe]
        \\(;B[rg]
        \\;W[ob])
        \\(;B[re]
        \\(;W[rd]
        \\;B[qg])
        \\(;W[pb]
        \\;W[ld]))))
        \\(;B[pe]
        \\;W[rf]))
    ;

    const collection = try parseSgfToRawCollection(std.testing.allocator, branched_sgf_string);
    defer collection.deinit(std.testing.allocator);
}
