pub const PlayerColour = enum {
    empty,
    black,
    white,
};

pub const ParseError = error{
    InvalidRawCoords,
};

pub const BoardCoords = struct {
    x: u32,
    y: u32,

    pub fn fromSgfCoords(string_coords: []const u8) !BoardCoords {
        if (!(string_coords.len == 2)) {
            return ParseError.InvalidRawCoords;
        }

        const x_char: u8 = string_coords[0];
        var x_coord: u32 = 0;
        if (x_char >= 'a' and x_char <= 'z') {
            x_coord = x_char - 'a';
        } else if (x_char >= 'A' and x_char <= 'Z') {
            x_coord = x_char - 'A';
        } else {
            return ParseError.InvalidRawCoords;
        }

        const y_char: u8 = string_coords[1];
        var y_coord: u32 = 0;
        if (y_char >= 'a' and y_char <= 'z') {
            y_coord = y_char - 'a';
        } else if (y_char >= 'A' and y_char <= 'Z') {
            y_coord = y_char - 'A';
        } else {
            return ParseError.InvalidRawCoords;
        }

        return .{ .x = x_coord, .y = y_coord };
    }
};
