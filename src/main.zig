const std = @import("std");

const parseRaw = @import("parse_raw.zig");

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const allocator: std.mem.Allocator = init.arena.allocator();

    const args: []const [:0]const u8 = try init.minimal.args.toSlice(allocator);

    const io = init.io;
    const contents = try std.Io.Dir.readFileAlloc(
        std.Io.Dir.cwd(),
        io,
        // "3-3_invasion_variations.sgf",
        // "Andrius-blit-2020-01-21.sgf",
        // "broken_sgf.sgf",
        args[1],
        allocator,
        .unlimited,
    );
    defer allocator.free(contents);

    const parsedSgf = (try parseRaw.parseSgf(allocator, contents));

    parsedSgf.pretty_print(.{});
}
