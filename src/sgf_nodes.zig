const std = @import("std");

const parseRaw = @import("parse_raw.zig");
const types = @import("types.zig");

pub const SgfError = error{
    NodeAlreadyHasParent,
    NodeHasNoParent,
    NodeIsNotChild,
    ChildParentInvalid,
    PropertyNotPresent,
    NodeDoesNotDefineMove,
};

pub const ValidationError = error{
    BlackAndWhiteMovesInSameNode,
};

// TODO Add an API to get properties by enum value
pub const PropertyType = enum {
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

pub const StonePlacement = struct {
    colour: types.PlayerColour,
    coords: types.BoardCoords,
};

pub const Property = struct {
    name: []const u8,
    values: std.ArrayList([]const u8),
    pub fn init(allocator: std.mem.Allocator, raw_name: []const u8, raw_values: [][]u8) !Property {
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

pub const SgfNode = struct {
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

    // True if the node has no children
    pub fn isLeafNode(this: *SgfNode) bool {
        return (this.children.items.len == 0);
    }

    // True if the node has no parent
    pub fn isRootNode(this: *SgfNode) bool {
        return (this.parent == null);
    }

    pub fn next(this: *SgfNode) ?*SgfNode {
        if (this.isLeafNode()) {
            return null;
        }
        return this.children.items[0]; // TODO add an active variation index?
    }

    pub fn previous(this: *SgfNode) ?*SgfNode {
        // No need to check anything since parent is Optional and we return an Optional
        return this.parent;
    }

    /// The index of the node in the linear list of nodes counted from the root
    /// node. Ignores variations, only counts how many nodes would be moved through from
    /// the root node to this one in its own variation branches. Note this is not the move
    /// number as not all nodes necessarily contain moves, plus the move number may be
    /// specified by SGF property.
    pub fn nodeIndex(this: *SgfNode) u32 {
        var count: u32 = 0;
        var cur_node: *SgfNode = this;
        while (cur_node.parent != null) {
            count += 1;
            cur_node = cur_node.parent.?;
        }
        return count;
    }

    /// A slice of nodes from the root node to this, in order. Does not include any
    /// children of this node. The caller is in charge of freeing the returned list.
    pub fn flatBranchList(this: *SgfNode, allocator: std.mem.Allocator) ![]*SgfNode {
        const num_nodes = this.nodeIndex() + 1;
        const nodes: []*SgfNode = try allocator.alloc(*SgfNode, num_nodes);

        var index: usize = nodes.len - 1;
        var cur_node: *SgfNode = this;
        while (true) {
            if (index == 0) {
                std.debug.assert(cur_node.parent == null);
            }

            nodes[index] = cur_node;
            if (cur_node.parent) |parent| {
                cur_node = parent;
                index -= 1;
            } else {
                std.debug.assert(index == 0);
                break;
            }
        }

        return nodes;
    }

    /// Perform checks on the validity of every node in the tree below this one
    pub fn validateTree(this: *SgfNode) !void {
        try this.validate();
        for (this.children.items) |child| {
            try child.validateTree();
        }

        // TODO
        // - tree does not loop
    }

    pub fn validate(this: *SgfNode) !void {
        // No mixing white and black moves
        const black_move = this.readProperty("B");
        const white_move = this.readProperty("W");
        if ((black_move != null) and (white_move != null)) {
            return ValidationError.BlackAndWhiteMovesInSameNode;
        }

        // No overlapping add-stone properties
    }

    pub fn readProperty(this: *SgfNode, name: []const u8) ?std.ArrayList([]const u8) {
        for (this.properties.items) |property| {
            if (std.mem.eql(u8, name, property.name)) {
                return property.values;
            }
        }
        return null;
    }

    pub fn readMove(this: *SgfNode) !?StonePlacement {
        if (this.readProperty(&.{'B'})) |values| {
            return .{
                .colour = types.PlayerColour.black,
                .coords = try types.BoardCoords.fromSgfCoords(values.items[0]),
            };
        }

        if (this.readProperty("W")) |values| {
            return .{
                .colour = types.PlayerColour.white,
                .coords = try types.BoardCoords.fromSgfCoords(values.items[0]),
            };
        }

        return null;
    }

    pub fn addChild(this: *SgfNode, allocator: std.mem.Allocator, child: *SgfNode) !void {
        if (child.parent != null) {
            return SgfError.NodeAlreadyHasParent;
        }

        try this.children.append(allocator, child);

        child.parent = this;
    }

    /// Remove this node from its parent. Sets this node's parent to null and removes it from the parent children
    pub fn cut(this: *SgfNode) !void {
        if (this.parent == null) {
            return SgfError.NodeHasNoParent;
        }

        try this.parent.?.removeChild(this);
        std.debug.assert(this.parent == null); // this should have been handled by the parent
    }

    pub fn removeChild(this: *SgfNode, removing_child: *SgfNode) !void {
        if (removing_child.parent != this) {
            return SgfError.ChildParentInvalid;
        }

        for (this.children.items, 0..) |child, index| {
            if (child == removing_child) {
                _ = this.children.orderedRemove(index);
                break;
            }
        } else {
            return SgfError.NodeIsNotChild;
        }

        removing_child.parent = null;
    }

    // pub fn treeLength(this: *SgfNode) u32 {
    //     var count: u32 = 1;
    //     var node = this;
    //     while (node.children.items.len > 0) {
    //         count += 1;
    //         node = node.children.items[0];
    //     }
    //     return count;
    // }

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

fn parseRawGameTree(allocator: std.mem.Allocator, raw: parseRaw.RawGameTreeStruct) !*SgfNode {
    // First add all the nodes in the game tree to the initial graph
    const root_node: *SgfNode = try SgfNode.initFromRawNode(allocator, raw.sequence.nodes[0]);
    var prev_node: *SgfNode = root_node;
    for (raw.sequence.nodes[1..]) |raw_node| {
        const sgf_node: *SgfNode = try SgfNode.initFromRawNode(allocator, raw_node);
        try prev_node.addChild(allocator, sgf_node);
        prev_node = sgf_node;
    }

    const last_node: *SgfNode = prev_node;

    // Each subtree now becomes a child of the last node
    for (raw.sub_game_trees) |sub_game_tree| {
        const sub_root_node: *SgfNode = try parseRawGameTree(allocator, sub_game_tree);
        try last_node.addChild(allocator, sub_root_node);
    }

    return root_node;
}

pub fn parseSgfString(allocator: std.mem.Allocator, string: []const u8) ![]*SgfNode {
    const collection = try parseRaw.parseSgf(allocator, string);
    defer collection.deinit(allocator);

    const root_nodes: []*SgfNode = try allocator.alloc(*SgfNode, collection.game_trees.len);
    for (collection.game_trees, 0..) |game_tree, index| {
        root_nodes[index] = try parseRawGameTree(allocator, game_tree);
    }

    return root_nodes;
}

pub fn parseSgfStringFirstGameTree(allocator: std.mem.Allocator, string: []const u8) !*SgfNode {
    const root_nodes: []*SgfNode = try parseSgfString(allocator, string);
    defer allocator.free(root_nodes);

    return root_nodes[0];
}

pub fn deinitRootNodeTreesAndContainer(allocator: std.mem.Allocator, root_nodes: []*SgfNode) void {
    for (root_nodes) |root_node| {
        root_node.deinitTree(allocator);
    }
    allocator.free(root_nodes);
}

fn debugPrintIndent(count: u32) void {
    if (count == 0) {
        return;
    }
    for (0..(count - 1)) |_| {
        std.debug.print(" ", .{});
    }
}

pub fn debugPrintNodeTree(root: *SgfNode, indent_count: u32) void {
    var cur_node: *SgfNode = root;
    while (true) {
        debugPrintIndent(indent_count);
        std.debug.print("Node->{d}\n", .{
            cur_node.children.items.len,
        });

        for (cur_node.properties.items) |property| {
            debugPrintIndent(indent_count + 4);
            std.debug.print("{s}: ", .{property.name});
            for (property.values.items) |value| {
                std.debug.print(" \"{s}\"", .{value});
            }
            std.debug.print("\n", .{});
        }

        if (cur_node.children.items.len == 0) {
            break;
        }

        if (cur_node.children.items.len > 1) {
            for (cur_node.children.items[1..]) |child| {
                debugPrintNodeTree(child, indent_count + 4);
            }
        }

        cur_node = cur_node.children.items[0];
    }
}

test {
    std.testing.refAllDecls(@This());
}

test "parse sgf to nodes" {
    const root_nodes = try parseSgfString(std.testing.allocator, "(;B[aa];W[bb])");
    defer deinitRootNodeTreesAndContainer(std.testing.allocator, root_nodes);
    try std.testing.expectEqual(1, root_nodes.len);
    try std.testing.expectEqual(1, root_nodes[0].children.items.len);
}

test "parse multiple game trees" {
    const root_nodes = try parseSgfString(std.testing.allocator, "(;B[aa];W[bb])(;W[cc];B[dd])");
    defer deinitRootNodeTreesAndContainer(std.testing.allocator, root_nodes);
    try std.testing.expectEqual(2, root_nodes.len);
}

test "parse complex branched sgf to nodes" {
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

    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, branched_sgf_string);
    defer root_node.deinitTree(std.testing.allocator);
}

test "read property" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;XZ[test_value 1][second_value 2])");
    defer root_node.deinitTree(std.testing.allocator);

    try std.testing.expectEqual(null, root_node.readProperty("FF"));

    const values = root_node.readProperty("XZ").?;
    try std.testing.expectEqual(2, values.items.len);
    try std.testing.expectEqualStrings("test_value 1", values.items[0]);
    try std.testing.expectEqualStrings("second_value 2", values.items[1]);
}

test "read move" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab];W[cd])");
    defer root_node.deinitTree(std.testing.allocator);

    const node1 = root_node;
    const expected_placement_1: StonePlacement = .{ .colour = types.PlayerColour.black, .coords = .{ .x = 0, .y = 1 } };
    try std.testing.expectEqual((try node1.readMove()).?, expected_placement_1);

    const node2 = root_node.children.items[0];
    const expected_placement_2: StonePlacement = .{ .colour = types.PlayerColour.white, .coords = .{ .x = 2, .y = 3 } };
    try std.testing.expectEqual((try node2.readMove()).?, expected_placement_2);
}

test "children" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab](;W[cd])(;B[ef])(;W[gh]))");
    defer root_node.deinitTree(std.testing.allocator);

    try std.testing.expectEqual(root_node.children.items.len, 3);
}

test "cut" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab](;W[cd])(;B[ef])(;W[gh]))");
    defer root_node.deinitTree(std.testing.allocator);
    try root_node.validateTree();

    try std.testing.expectEqual(root_node.children.items.len, 3);
    const child = root_node.children.items[1];

    try child.cut();
    defer child.deinitTree(std.testing.allocator);
    try std.testing.expect(child.parent == null);

    try std.testing.expectError(SgfError.NodeHasNoParent, root_node.cut());
}

test "remove child" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab](;W[cd])(;B[ef])(;W[gh]))");
    defer root_node.deinitTree(std.testing.allocator);
    try root_node.validateTree();

    try std.testing.expectEqual(root_node.children.items.len, 3);
    const child = root_node.children.items[1];

    try root_node.removeChild(child);
    defer child.deinitTree(std.testing.allocator);
    try std.testing.expect(child.parent == null);

    try std.testing.expectError(SgfError.ChildParentInvalid, root_node.removeChild(root_node));

    const second_root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;W[zz];B[yy])");
    defer second_root_node.deinitTree(std.testing.allocator);
    try std.testing.expectError(SgfError.ChildParentInvalid, root_node.removeChild(second_root_node.children.items[0]));
}

test "validate" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab]W[cd])");
    defer root_node.deinitTree(std.testing.allocator);

    try std.testing.expectError(ValidationError.BlackAndWhiteMovesInSameNode, root_node.validate());
    try std.testing.expectError(ValidationError.BlackAndWhiteMovesInSameNode, root_node.validateTree());
}

test "add child" {
    const root_node_1 = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab];W[cd])");
    defer root_node_1.deinitTree(std.testing.allocator);

    const root_node_2 = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[xz])");

    try root_node_1.addChild(std.testing.allocator, root_node_2);
    try std.testing.expectEqual(root_node_1.children.items[1], root_node_2);
    try std.testing.expectEqual(root_node_1, root_node_2.parent);

    try std.testing.expectError(
        SgfError.NodeAlreadyHasParent,
        root_node_1.addChild(std.testing.allocator, root_node_1.children.items[0]),
    );
}

test "node index" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab];W[cd](;B[ef])(;W[gh])(;W[ij]))");
    defer root_node.deinitTree(std.testing.allocator);

    try std.testing.expectEqual(0, root_node.nodeIndex());
    try std.testing.expectEqual(1, root_node.children.items[0].nodeIndex());
    try std.testing.expectEqual(2, root_node.children.items[0].children.items[0].nodeIndex());
    try std.testing.expectEqual(2, root_node.children.items[0].children.items[1].nodeIndex());
    try std.testing.expectEqual(2, root_node.children.items[0].children.items[2].nodeIndex());
}

test "get nodes list" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab];W[cd](;B[ef])(;W[gh];B[ij]))");
    defer root_node.deinitTree(std.testing.allocator);

    const node_1_list: []*SgfNode = try root_node.children.items[0].flatBranchList(std.testing.allocator);
    defer std.testing.allocator.free(node_1_list);
    try std.testing.expectEqual(2, node_1_list.len);
    try std.testing.expectEqual(root_node, node_1_list[0]);
    try std.testing.expectEqual(root_node.children.items[0], node_1_list[1]);

    const node_2_list: []*SgfNode = try root_node.children.items[0].children.items[1].flatBranchList(std.testing.allocator);
    defer std.testing.allocator.free(node_2_list);
    try std.testing.expectEqual(3, node_2_list.len);
    try std.testing.expectEqual(root_node, node_2_list[0]);
    try std.testing.expectEqual(root_node.children.items[0], node_2_list[1]);
    try std.testing.expectEqual(root_node.children.items[0].children.items[1], node_2_list[2]);
}

test "is root/leaf node" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab];W[cd](;B[ef])(;W[gh];B[ij]))");
    defer root_node.deinitTree(std.testing.allocator);

    try std.testing.expectEqual(false, root_node.isLeafNode());
    try std.testing.expectEqual(false, root_node.children.items[0].isLeafNode());
    try std.testing.expectEqual(true, root_node.children.items[0].children.items[0].isLeafNode());
    try std.testing.expectEqual(false, root_node.children.items[0].children.items[1].isLeafNode());

    try std.testing.expectEqual(true, root_node.isRootNode());
    try std.testing.expectEqual(false, root_node.children.items[0].isRootNode());
    try std.testing.expectEqual(false, root_node.children.items[0].children.items[0].isRootNode());
    try std.testing.expectEqual(false, root_node.children.items[0].children.items[1].isRootNode());
}

test "next / previous" {
    const root_node = try parseSgfStringFirstGameTree(std.testing.allocator, "(;B[ab];W[cd])");
    defer root_node.deinitTree(std.testing.allocator);

    const node_1 = root_node;
    const node_2 = root_node.children.items[0];

    try std.testing.expectEqual(null, node_1.previous());
    try std.testing.expectEqual(node_2, node_1.next());

    try std.testing.expectEqual(node_1, node_2.previous());
    try std.testing.expectEqual(null, node_2.next());
}
