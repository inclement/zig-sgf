const std = @import("std");

const types = @import("types.zig");

const BoardLogicError = error{
    InvalidMoveColour,
    CoordsExceedBoardSize,
    PointAlreadyOccupied,
};

const Board = struct {
    size: u32,
    grid: [][]types.PlayerColour,
    allow_suicide: bool = false,

    pub fn init(allocator: std.mem.Allocator, size: u32) !*Board {
        const this: *Board = try allocator.create(Board);
        this.size = size;
        this.grid = try allocator.alloc([]types.PlayerColour, size);
        for (0..(size)) |index| {
            this.grid[index] = try allocator.alloc(types.PlayerColour, size);
        }

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

    pub fn playMove(this: *Board, colour: types.PlayerColour, coords: types.BoardCoords) !void {
        if (colour == types.PlayerColour.empty) {
            return BoardLogicError.InvalidMoveColour;
        }

        if ((coords.x >= this.size) or (coords.y >= this.size)) {
            return BoardLogicError.CoordsExceedBoardSize;
        }

        const current_colour: types.PlayerColour = this.grid[coords.x][coords.y];
        if (current_colour != types.PlayerColour.empty) {
            return BoardLogicError.PointAlreadyOccupied;
        }

        this.grid[coords.x][coords.y] = colour;
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

    try board.playMove(.black, .{ .x = 3, .y = 5 });
    try board.playMove(.white, .{ .x = 3, .y = 6 });

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

    try board.playMove(.black, .{ .x = 3, .y = 5 });
    try board.playMove(.white, .{ .x = 3, .y = 6 });

    try std.testing.expectError(BoardLogicError.InvalidMoveColour, board.playMove(.empty, .{ .x = 1, .y = 2 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(.black, .{ .x = 3, .y = 5 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(.black, .{ .x = 3, .y = 6 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(.white, .{ .x = 3, .y = 5 }));
    try std.testing.expectError(BoardLogicError.PointAlreadyOccupied, board.playMove(.white, .{ .x = 3, .y = 6 }));

    try board.playMove(.white, .{ .x = 8, .y = 8 });
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(.black, .{ .x = 9, .y = 8 }));
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(.black, .{ .x = 9, .y = 8 }));
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(.white, .{ .x = 8, .y = 9 }));
    try std.testing.expectError(BoardLogicError.CoordsExceedBoardSize, board.playMove(.white, .{ .x = 8, .y = 9 }));
}
