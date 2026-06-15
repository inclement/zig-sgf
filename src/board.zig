const std = @import("std");

const types = @import("types.zig");

const BoardLogicError = error{
    InvalidMoveColour,
    CoordsExceedBoardSize,
    PointAlreadyOccupied,
    PointNotOccupied,
    MoveIsSuicide,
};

fn valueInArrayList(comptime T: type, value: T, list: std.ArrayList(T)) bool {
    for (list.items) |item| {
        if (std.meta.eql(value, item)) {
            return true;
        }
    }
    return false;
}

const Board = struct {
    size: u32,
    grid: [][]types.PlayerColour,
    // allow_suicide: bool = false,
    white_stones_captured: u32 = 0,
    black_stones_captured: u32 = 0,

    pub fn init(allocator: std.mem.Allocator, size: u32) !*Board {
        const this: *Board = try allocator.create(Board);
        this.size = size;
        this.grid = try allocator.alloc([]types.PlayerColour, size);
        for (0..(size)) |index| {
            this.grid[index] = try allocator.alloc(types.PlayerColour, size);
        }
        this.white_stones_captured = 0;
        this.black_stones_captured = 0;

        this.clear();

        return this;
    }

    pub fn deinit(this: *Board, allocator: std.mem.Allocator) void {
        for (this.grid) |row| {
            allocator.free(row);
        }
        allocator.free(this.grid);
        allocator.destroy(this);
    }

    pub fn clear(this: *Board) void {
        for (this.grid) |row| {
            for (0..row.len) |index| {
                row[index] = types.PlayerColour.empty;
            }
        }
    }

    pub fn playMove(this: *Board, allocator: std.mem.Allocator, colour: types.PlayerColour, coord: types.BoardCoords) !void {
        if (colour == types.PlayerColour.empty) {
            return BoardLogicError.InvalidMoveColour;
        }

        if ((coord.x >= this.size) or (coord.y >= this.size)) {
            return BoardLogicError.CoordsExceedBoardSize;
        }

        const current_colour: types.PlayerColour = this.grid[coord.x][coord.y];
        if (current_colour != types.PlayerColour.empty) {
            return BoardLogicError.PointAlreadyOccupied;
        }

        // For each of left/right/up/down:
        // - Look through group to check if it's captured
        // - If yes, remove it and mark this liberty as empty
        // - If no, move on
        // - If no captures, check if the played stone is in a captured group (adjacent same-colour groups have 2+ liberties)
        // - If yes, result depends on if suicide allowed
        // - If no, play the stone
        var left_provides_liberties: bool = false;
        var right_provides_liberties: bool = false;
        var up_provides_liberties: bool = false;
        var down_provides_liberties: bool = false;

        const maybe_left_coord = this.leftFrom(coord);
        if (maybe_left_coord) |left_coord| {
            const left_colour = this.grid[left_coord.x][left_coord.y];
            if (left_colour == .empty) {
                left_provides_liberties = true;
            } else {
                const has_liberties = try this.groupHasAtLeastOneLibertyOtherThan(allocator, left_coord, coord);
                if (left_colour == colour) {
                    left_provides_liberties = has_liberties;
                } else {
                    if (!has_liberties) {
                        try this.captureGroup(left_coord);
                    }
                    left_provides_liberties = !has_liberties;
                }
            }
        }

        const maybe_right_coord = this.rightFrom(coord);
        if (maybe_right_coord) |right_coord| {
            const right_colour = this.grid[right_coord.x][right_coord.y];
            if (right_colour == .empty) {
                right_provides_liberties = true;
            } else {
                const has_liberties = try this.groupHasAtLeastOneLibertyOtherThan(allocator, right_coord, coord);
                if (right_colour == colour) {
                    right_provides_liberties = has_liberties;
                } else {
                    if (!has_liberties) {
                        try this.captureGroup(right_coord);
                    }
                    right_provides_liberties = !has_liberties;
                }
            }
        }

        const maybe_up_coord = this.upFrom(coord);
        if (maybe_up_coord) |up_coord| {
            const up_colour = this.grid[up_coord.x][up_coord.y];
            if (up_colour == .empty) {
                up_provides_liberties = true;
            } else {
                const has_liberties = try this.groupHasAtLeastOneLibertyOtherThan(allocator, up_coord, coord);
                if (up_colour == colour) {
                    up_provides_liberties = has_liberties;
                } else {
                    if (!has_liberties) {
                        try this.captureGroup(up_coord);
                    }
                    up_provides_liberties = !has_liberties;
                }
            }
        }

        const maybe_down_coord = this.downFrom(coord);
        if (maybe_down_coord) |down_coord| {
            const down_colour = this.grid[down_coord.x][down_coord.y];
            if (down_colour == .empty) {
                down_provides_liberties = true;
            } else {
                const has_liberties = try this.groupHasAtLeastOneLibertyOtherThan(allocator, down_coord, coord);
                if (down_colour == colour) {
                    down_provides_liberties = has_liberties;
                } else {
                    if (!has_liberties) {
                        try this.captureGroup(down_coord);
                    }
                    down_provides_liberties = !has_liberties;
                }
            }
        }

        // At this point we've applied any captures of adjacent groups, but the group of
        // the newly-played stone might have no liberties.
        if (!(left_provides_liberties or right_provides_liberties or up_provides_liberties or down_provides_liberties)) {
            // TODO Support suicide
            return BoardLogicError.MoveIsSuicide;
        }

        // At this point we've performed captures and checked the move is valid, so only
        // thing left is to actually make the move
        this.grid[coord.x][coord.y] = colour;
    }

    fn captureGroup(this: *Board, coord: types.BoardCoords) !void {
        const colour = this.grid[coord.x][coord.y];
        switch (colour) {
            types.PlayerColour.empty => {
                return BoardLogicError.PointNotOccupied;
            },
            types.PlayerColour.black => {
                this.black_stones_captured += 1;
            },
            types.PlayerColour.white => {
                this.white_stones_captured += 1;
            },
        }

        this.grid[coord.x][coord.y] = .empty;

        // Recurse into neighbours
        const neighbour_coords: [4]?types.BoardCoords = .{
            this.leftFrom(coord),
            this.rightFrom(coord),
            this.upFrom(coord),
            this.downFrom(coord),
        };
        for (neighbour_coords) |maybe_neighbour| {
            if (maybe_neighbour) |neighbour| {
                if (this.grid[neighbour.x][neighbour.y] == colour) {
                    try this.captureGroup(neighbour);
                }
            }
        }
    }

    fn groupHasAtLeastOneLibertyOtherThan(
        this: *Board,
        allocator: std.mem.Allocator,
        coord: types.BoardCoords,
        other_than: types.BoardCoords,
    ) !bool {
        const group_colour: types.PlayerColour = this.grid[coord.x][coord.y];
        if (group_colour == .empty) {
            return BoardLogicError.InvalidMoveColour;
        }

        var stones_to_check: std.ArrayList(types.BoardCoords) = .empty;
        defer stones_to_check.deinit(allocator);
        try stones_to_check.append(allocator, coord);

        var visited_stones: std.ArrayList(types.BoardCoords) = .empty;
        defer visited_stones.deinit(allocator);

        std.debug.assert(valueInArrayList(types.BoardCoords, stones_to_check.items[0], stones_to_check));

        while (stones_to_check.pop()) |stone_to_check| {
            // For each adjacent coordinate, if it's a free liberty satisfying the
            // condition then we can return, otherwise add it to the lists we're iterating
            // through
            std.debug.assert(!valueInArrayList(types.BoardCoords, stone_to_check, visited_stones));
            try visited_stones.append(allocator, stone_to_check);
            const maybe_left_coord = this.leftFrom(stone_to_check);
            if (maybe_left_coord) |left_coord| {
                if (try this.iterateLibertySearch(allocator, group_colour, left_coord, other_than, &visited_stones, &stones_to_check)) {
                    return true;
                }
            }
            const maybe_right_coord = this.rightFrom(stone_to_check);
            if (maybe_right_coord) |right_coord| {
                if (try this.iterateLibertySearch(allocator, group_colour, right_coord, other_than, &visited_stones, &stones_to_check)) {
                    return true;
                }
            }
            const maybe_up_coord = this.upFrom(stone_to_check);
            if (maybe_up_coord) |up_coord| {
                if (try this.iterateLibertySearch(allocator, group_colour, up_coord, other_than, &visited_stones, &stones_to_check)) {
                    return true;
                }
            }
            const maybe_down_coord = this.downFrom(stone_to_check);
            if (maybe_down_coord) |down_coord| {
                if (try this.iterateLibertySearch(allocator, group_colour, down_coord, other_than, &visited_stones, &stones_to_check)) {
                    return true;
                }
            }
        }

        // If we reached the end of the while loop without already completing, there is no other liberty
        return false;
    }

    // If target coord is empty and isn't the other_than target, return true. Otherwise
    // return false and add the coord to the stones to check if not already handled.
    fn iterateLibertySearch(
        this: *Board,
        allocator: std.mem.Allocator,
        group_colour: types.PlayerColour,
        coord: types.BoardCoords,
        other_than: types.BoardCoords,
        visited_stones: *std.ArrayList(types.BoardCoords),
        stones_to_check: *std.ArrayList(types.BoardCoords),
    ) !bool {
        const value: types.PlayerColour = this.grid[coord.x][coord.y];
        if (value == .empty) {
            if ((coord.x != other_than.x) or (coord.y != other_than.y)) {
                return true;
            }
            // If the coord is empty but didn't match, it's the other_than coord so we ignore it
        } else if (value != group_colour) {
            // Adjacent stone isn't in our group so nothing to do
        } else {
            // Adjacent stone is another one in our group so add to the list to iterate through
            if (!valueInArrayList(types.BoardCoords, coord, visited_stones.*) and !valueInArrayList(types.BoardCoords, coord, stones_to_check.*)) {
                try stones_to_check.append(allocator, coord);
            }
        }
        return false;
    }

    pub fn leftFrom(this: *Board, coords: types.BoardCoords) ?types.BoardCoords {
        _ = this; // we do want this to be a member function
        if (coords.x > 0) {
            return .{ .x = coords.x - 1, .y = coords.y };
        }
        return null;
    }

    pub fn rightFrom(this: *Board, coords: types.BoardCoords) ?types.BoardCoords {
        if (coords.x < (this.size - 1)) {
            return .{ .x = coords.x + 1, .y = coords.y };
        }
        return null;
    }

    pub fn downFrom(this: *Board, coords: types.BoardCoords) ?types.BoardCoords {
        _ = this; // we do want this to be a member function
        if (coords.y > 0) {
            return .{ .x = coords.x, .y = coords.y - 1 };
        }
        return null;
    }

    pub fn upFrom(this: *Board, coords: types.BoardCoords) ?types.BoardCoords {
        if (coords.y < (this.size - 1)) {
            return .{ .x = coords.x, .y = coords.y + 1 };
        }
        return null;
    }
};

test "init and deinit" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    for (board.grid) |row| {
        for (0..row.len) |index| {
            try std.testing.expectEqual(types.PlayerColour.empty, row[index]);
        }
    }
}

test "play move success" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 5 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 6 });

    for (0..board.size) |row_index| {
        for (0..board.size) |col_index| {
            const expected_colour: types.PlayerColour = (if (row_index == 3 and col_index == 5)
                .black
            else if (row_index == 3 and col_index == 6)
                .white
            else
                .empty);
            try std.testing.expectEqual(expected_colour, board.grid[row_index][col_index]);
        }
    }
}

test "play move failure" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 5 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 6 });

    try std.testing.expectError(BoardLogicError.InvalidMoveColour, board.playMove(std.testing.allocator, .empty, .{ .x = 1, .y = 2 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 5 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 6 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 5 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 6 }));

    try board.playMove(std.testing.allocator, .white, .{ .x = 8, .y = 8 });
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(std.testing.allocator, .black, .{ .x = 9, .y = 8 }));
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(std.testing.allocator, .black, .{ .x = 9, .y = 8 }));
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(std.testing.allocator, .white, .{ .x = 8, .y = 9 }));
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(std.testing.allocator, .white, .{ .x = 8, .y = 9 }));
}

test "simple capture" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 3 });
    try std.testing.expectEqual(types.PlayerColour.black, board.grid[3][3]);
    try board.playMove(std.testing.allocator, .white, .{ .x = 2, .y = 3 });
    try std.testing.expectEqual(types.PlayerColour.black, board.grid[3][3]);
    try board.playMove(std.testing.allocator, .white, .{ .x = 4, .y = 3 });
    try std.testing.expectEqual(types.PlayerColour.black, board.grid[3][3]);
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 2 });
    try std.testing.expectEqual(types.PlayerColour.black, board.grid[3][3]);
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 4 });
    try std.testing.expectEqual(types.PlayerColour.empty, board.grid[3][3]);

    try std.testing.expectEqual(1, board.black_stones_captured);
    try std.testing.expectEqual(0, board.white_stones_captured);
}

test "larger groups capture" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 3 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 4 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 4, .y = 3 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 4, .y = 4 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 5, .y = 4 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 7, .y = 7 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 2, .y = 4 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 7, .y = 8 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 5 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 8, .y = 7 });
    try std.testing.expectEqual(types.PlayerColour.white, board.grid[3][4]);
    try std.testing.expectEqual(types.PlayerColour.white, board.grid[4][4]);
    try board.playMove(std.testing.allocator, .black, .{ .x = 4, .y = 5 });
    try std.testing.expectEqual(types.PlayerColour.empty, board.grid[3][4]);
    try std.testing.expectEqual(types.PlayerColour.empty, board.grid[4][4]);

    try std.testing.expectEqual(0, board.black_stones_captured);
    try std.testing.expectEqual(2, board.white_stones_captured);
}

test "board-spanning capture" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    for (0..9) |index| {
        try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = @intCast(index) });
    }
    for (0..9) |index| {
        try board.playMove(std.testing.allocator, .white, .{ .x = 2, .y = @intCast(index) });
        try std.testing.expectEqual(types.PlayerColour.black, board.grid[3][4]); // test one example point
    }

    for (0..8) |index| {
        try board.playMove(std.testing.allocator, .white, .{ .x = 4, .y = @intCast(index) });
        try std.testing.expectEqual(types.PlayerColour.black, board.grid[3][4]); // test one example point
    }

    try board.playMove(std.testing.allocator, .white, .{ .x = 4, .y = 8 });
    try std.testing.expectEqual(types.PlayerColour.empty, board.grid[3][4]); // test one example point

    try std.testing.expectEqual(9, board.black_stones_captured);
    try std.testing.expectEqual(0, board.white_stones_captured);
}

test "one group spans multiple liberties in capture" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 3 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 4 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 4, .y = 3 });

    try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 2 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 4, .y = 2 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 5, .y = 3 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 2, .y = 3 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 2, .y = 4 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 5 });

    try std.testing.expectEqual(types.PlayerColour.white, board.grid[3][3]);
    try board.playMove(std.testing.allocator, .black, .{ .x = 4, .y = 4 });
    try std.testing.expectEqual(types.PlayerColour.empty, board.grid[3][3]);

    try std.testing.expectEqual(0, board.black_stones_captured);
    try std.testing.expectEqual(3, board.white_stones_captured);
}

test "forbid suicide" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    try board.playMove(std.testing.allocator, .white, .{ .x = 2, .y = 3 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 4, .y = 3 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 2 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 3, .y = 4 });

    try std.testing.expectError(
        BoardLogicError.MoveIsSuicide,
        board.playMove(std.testing.allocator, .black, .{ .x = 3, .y = 3 }),
    );
    try std.testing.expectEqual(types.PlayerColour.empty, board.grid[3][3]);

    try std.testing.expectEqual(0, board.black_stones_captured);
    try std.testing.expectEqual(0, board.white_stones_captured);
}

test "forbid more complex suicide" {
    const board: *Board = try Board.init(std.testing.allocator, 9);
    defer board.deinit(std.testing.allocator);

    try board.playMove(std.testing.allocator, .white, .{ .x = 0, .y = 2 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 1, .y = 1 });
    try board.playMove(std.testing.allocator, .white, .{ .x = 2, .y = 0 });

    try board.playMove(std.testing.allocator, .black, .{ .x = 0, .y = 1 });
    try board.playMove(std.testing.allocator, .black, .{ .x = 1, .y = 0 });

    try std.testing.expectError(
        BoardLogicError.MoveIsSuicide,
        board.playMove(std.testing.allocator, .black, .{ .x = 0, .y = 0 }),
    );
    try std.testing.expectEqual(types.PlayerColour.empty, board.grid[0][0]);
    try std.testing.expectEqual(types.PlayerColour.black, board.grid[0][1]);
    try std.testing.expectEqual(types.PlayerColour.black, board.grid[1][0]);

    try std.testing.expectEqual(0, board.black_stones_captured);
    try std.testing.expectEqual(0, board.white_stones_captured);
}
