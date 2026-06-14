//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

const parseRaw = @import("parse_raw.zig");
pub const sgfNodes = @import("sgf_nodes.zig");
pub const board = @import("board.zig");
const types = @import("types.zig");
const mecha = @import("mecha");

pub const parseSgfString = sgfNodes.parseSgfString;

test {
    std.testing.refAllDecls(@This());
    _ = sgfNodes;
    _ = board;
    _ = mecha;
    _ = parseRaw;
    _ = types;
}
