const std = @import("std");
const mecha = @import("mecha");

const RawPropertyStruct = struct {
    ident: []const u8,
    values: [][]const u8,
    fn fromParsedProperty(result: struct { []const u8, [][]const u8 }) RawPropertyStruct {
        return .{
            .ident = result[0],
            .values = result[1],
        };
    }

    pub fn deinit(this: *const RawPropertyStruct, allocator: std.mem.Allocator) void {
        allocator.free(this.ident);
        allocator.free(this.values);
    }
};

const RawNodeStruct = struct {
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
    }
};

const RawSequenceStruct = struct {
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
    }
};

const RawGameTreeStruct = struct {
    sequence: RawSequenceStruct,
    sub_game_trees: []RawGameTreeStruct,
    fn fromParsedGameTree(result: struct { RawSequenceStruct, []RawGameTreeStruct }) RawGameTreeStruct {
        return .{
            .sequence = result[0],
            .sub_game_trees = result[1],
        };
    }

    pub fn deinit(this: *const RawGameTreeStruct, allocator: std.mem.Allocator) void {
        for (this.sub_game_trees) |game_tree| {
            game_tree.deinit(allocator);
        }

        this.sequence.deinit(allocator);
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

const parseIgnoreWhitespace = mecha.many(mecha.ascii.whitespace, .{}).discard();
const parseCValueType = mecha.oneOf(.{
    // TODO: allow escaped close bracket
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

fn debugPrintNSpaces(num: u32) void {
    for (0..num) |_| {
        std.debug.print(" ", .{});
    }
}

pub fn parseSgf(allocator: std.mem.Allocator, text: []u8) !RawGameTreeStruct {
    // TODO Add Collection level of parsing
    return (try parseGameTree.parse(allocator, text)).value.ok;
}
