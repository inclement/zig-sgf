const std = @import("std");

const parseRaw = @import("parse_raw.zig");

const SgfError = error{
    NodeAlreadyHasParent,
};

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

        for (this.values.items) |value| {
            allocator.free(value);
        }
        this.values.deinit(allocator);
    }
};

const SgfNode = struct {
    properties: std.ArrayList(Property),
    parent: ?*SgfNode,
    children: std.ArrayList(*SgfNode),

    pub fn init(allocator: std.mem.Allocator) !*SgfNode {
        const this: *SgfNode = try allocator.create(SgfNode);
        this.properties = .empty;
        this.parent = null;
        this.children = .empty;
        return this;
    }

    pub fn initFromRawNode(allocator: std.mem.Allocator, raw_node: parseRaw.RawNodeStruct) !*SgfNode {
        const node = try SgfNode.init(allocator);

        for (raw_node.properties) |property| {
            try node.properties.append(allocator, try Property.fromRawProperty(property, allocator));
        }
        return node;
    }

    pub fn addChild(this: *SgfNode, allocator: std.mem.Allocator, child: *SgfNode) !void {
        if (child.parent != null) {
            return SgfError.NodeAlreadyHasParent;
        }

        try this.children.append(allocator, child);
    }

    pub fn deinit(this: *SgfNode, allocator: std.mem.Allocator) void {
        for (this.properties.items) |*property| {
            property.deinit(allocator);
        }
        this.properties.deinit(allocator);
        this.children.deinit(allocator);

        allocator.destroy(this);
    }

    pub fn deinitTree(this: *SgfNode, allocator: std.mem.Allocator) void {
        for (this.children.items) |child| {
            child.deinitTree(allocator);
        }
        this.deinit(allocator);
    }
};

fn parseSgf(allocator: std.mem.Allocator, raw: parseRaw.RawGameTreeStruct) !*SgfNode {
    // First add all the nodes in the game tree to the initial graph
    const root_node: *SgfNode = try SgfNode.initFromRawNode(allocator, raw.sequence.nodes[0]);
    var prev_node: *SgfNode = root_node;
    for (raw.sequence.nodes) |raw_node| {
        const sgf_node: *SgfNode = try SgfNode.initFromRawNode(allocator, raw_node);
        try prev_node.addChild(allocator, sgf_node);
        prev_node = sgf_node;
    }

    const last_node: *SgfNode = prev_node;

    // Each subtree now becomes a child of the last node
    for (raw.sub_game_trees) |sub_game_tree| {
        const sub_root_node: *SgfNode = try parseSgf(allocator, sub_game_tree);
        try last_node.addChild(allocator, sub_root_node);
    }

    return root_node;
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

    var root_node: *SgfNode = try parseSgf(allocator, raw_sgf);
    defer root_node.deinitTree(allocator);

    raw_sgf.pretty_print(.{});

    std.debug.print("{any}\n", .{root_node});
}
