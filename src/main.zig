const std = @import("std");

const parseRaw = @import("parse_raw.zig");
const sgfNodes = @import("sgf_nodes.zig");
const mecha = @import("mecha");

pub fn main(init: std.process.Init) !void {
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

    const root_nodes: []*sgfNodes.SgfNode = try sgfNodes.parseSgfString(allocator, contents);
    defer sgfNodes.deinitRootNodeTreesAndContainer(allocator, root_nodes);

    std.debug.print("Read {d} game trees from {s}\n", .{ root_nodes.len, args[1] });

    const root_node: *sgfNodes.SgfNode = root_nodes[0];

    sgfNodes.debugPrintNodeTree(root_node, 0);
}
