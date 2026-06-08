const std = @import("std");

const parseRaw = @import("parse_raw.zig");

const PropertyType = enum {
    black_move,
    white_move,
    move_number,
    add_black,
    add_empty,
    add_white,
    player,
    comment,
    name,
    mark_circle,
    mark_dim,
    mark_x,
    mark_square,
    mark_triangle,
    charset,
    board_size,
    black_rank,
    white_rank,
    date,
    black_name,
    white_name,
    result,
    rules,
    time_limits,
    black_time_left,
    white_time_left,
    black_byo_yomi_moves_left,
    white_byo_yomi_moves_left,
    unparsed,
};

const Property = struct {
    name: []const u8,
    values: std.ArrayList([]const u8),
    pub fn init(allocator: std.mem.Allocator, raw_name: []const u8, raw_values: [][]const u8) !Property {
        const name_mem = try allocator.alloc(u8, raw_name.len);
        const name_slice: []u8 = name_mem;
        @memcpy(name_slice, raw_name);

        var list: std.ArrayList([]const u8) = .empty;
        for (raw_values) |raw_value| {
            const value_mem = try allocator.alloc(u8, raw_value.len);
            const value_slice: []u8 = value_mem;
            @memcpy(value_slice, raw_value);

            try list.append(allocator, value_slice);
        }

        return .{
            .name = name_slice,
            .values = list,
        };
    }
    pub fn fromRawProperty(raw: parseRaw.RawPropertyStruct, allocator: std.mem.Allocator) !Property {
        const property = try Property.init(allocator, raw.ident, raw.values);
        return property;
    }

    pub fn deinit(this: *Property, allocator: std.mem.Allocator) void {
        allocator.free(this.name);

        for (this.values) |value| {
            allocator.free(value);
        }
        this.values.deinit(allocator);
    }
};

const Node = struct {
    properties: std.ArrayList(Property),
    pub fn init() Node {
        return .{ .properties = .empty };
    }
    pub fn fromRawNode(raw: parseRaw.RawNodeStruct, allocator: std.mem.Allocator) !Node {
        var node: Node = Node.init();
        for (raw.properties) |property| {
            try node.properties.append(allocator, try Property.fromRawProperty(property, allocator));
        }
        return node;
    }
    pub fn deinit(this: *Node, allocator: std.mem.Allocator) void {
        for (this.properties) |property| {
            property.deinit(allocator);
        }
        this.properties.deinit(allocator);
    }
};

const GameTree = struct {
    nodes: std.ArrayList(Node),
    sub_game_trees: bool = false,

    pub fn init() GameTree {
        return .{ .nodes = .empty };
    }

    pub fn fromRawGameTree(raw: parseRaw.RawGameTreeStruct, allocator: std.mem.Allocator) !GameTree {
        var game_tree: GameTree = GameTree.init();
        for (raw.sequence.nodes) |node| {
            try game_tree.nodes.append(allocator, try Node.fromRawNode(node, allocator));
        }
        return game_tree;
    }

    pub fn deinit(this: *GameTree, allocator: std.mem.Allocator) void {
        for (this.nodes) |node| {
            node.deinit(allocator);
        }
        this.nodes.deinit(allocator);
    }
};

fn parseSgf(allocator: std.mem.Allocator, raw: parseRaw.RawGameTreeStruct) !GameTree {
    return GameTree.fromRawGameTree(raw, allocator);
}

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const allocator: std.mem.Allocator = init.arena.allocator();

    const args: []const [:0]const u8 = try init.minimal.args.toSlice(allocator);

    const io = init.io;
    const contents: []u8 = try std.Io.Dir.readFileAlloc(
        std.Io.Dir.cwd(),
        io,
        args[1],
        allocator,
        .unlimited,
    );
    defer allocator.free(contents);

    const raw_sgf = (try parseRaw.parseSgf(allocator, contents));
    defer raw_sgf.deinit(allocator);

    const game_tree = parseSgf(allocator, raw_sgf);
    std.debug.print("{any}\n", .{game_tree});

    raw_sgf.pretty_print(.{});
}
