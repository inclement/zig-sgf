const std = @import("std");

const parseRaw = @import("parse_raw.zig");
const sgfNodes = @import("sgf_nodes.zig");

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

    const raw_sgf = (try parseRaw.parseSgf(allocator, contents));
    defer raw_sgf.deinit(allocator);

    var root_node: *sgfNodes.SgfNode = try sgfNodes.parseSgf(allocator, raw_sgf);
    defer root_node.deinitTree(allocator);

    // raw_sgf.pretty_print(.{});

    std.debug.print("{any}\n", .{root_node});
    sgfNodes.debugPrintNodeTree(root_node, 0);

    var cur_node = root_node;
    while (cur_node.next()) |next| {
        cur_node = next;
        std.debug.print("Move: {any}\n", .{cur_node.readMove()});
    }
}
