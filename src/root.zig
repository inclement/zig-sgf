//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const Io = std.Io;

const parseRaw = @import("parse_raw.zig");
const sgfNodes = @import("sgf_nodes.zig");
const mecha = @import("mecha");

pub const parseSgfString = sgfNodes.parseSgfString;

test {
    std.testing.refAllDecls(@This());
    _ = sgfNodes;
    _ = mecha;
    _ = parseRaw;
}
