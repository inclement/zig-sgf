const std = @import("std");

const mecha = @import("mecha");

const Io = std.Io;

const zig_sgf = @import("zig_sgf");

const example_fragment =
    \\(;
    \\FF[4]
    // \\CA[UTF-8]
    // \\GM[1]
    // \\DT[2026-05-25]
    // \\PC[OGS: https://online-go.com/game/87302596]
    // \\GN[Friendly Match]
    // \\PB[saucepan]
    // \\PW[GeRui]
    // \\BR[2d]
    // \\WR[1d]
    // \\TM[30]OT[5x10 byo-yomi]
    // \\RE[W+11.5]
    // \\SZ[19]
    // \\KM[6.5]
    // \\RU[Japanese]
    // \\;B[pd]
    // \\(;W[dp]
    // \\C[GeRui: hi
    // \\]
    // \\))
    \\)
;

const example_sgf =
    \\(;FF[4]
    \\CA[UTF-8]
    \\GM[1]
    \\DT[2026-05-25]
    \\PC[OGS: https://online-go.com/game/87302596]
    \\GN[Friendly Match]
    \\PB[saucepan]
    \\PW[GeRui]
    \\BR[2d]
    \\WR[1d]
    \\TM[30]OT[5x10 byo-yomi]
    \\RE[W+11.5]
    \\SZ[19]
    \\KM[6.5]
    \\RU[Japanese]
    \\;B[pd]
    \\(;W[dp]
    \\C[GeRui: hi
    \\]
    \\(;B[pp]
    \\(;W[dc]
    \\(;B[ce]
    \\(;W[dh]
    \\(;B[ed]
    \\(;W[dd]
    \\(;B[de]
    \\(;W[ee]
    \\(;B[fd]
    \\(;W[ef]
    \\(;B[bc]
    \\(;W[fb]
    \\(;B[gb]
    \\(;W[bb]
    \\(;B[bd]
    \\(;W[fc]
    \\(;B[gc]
    \\(;W[gd]
    \\(;B[fe]
    \\(;W[hd]
    \\(;B[ff]
    \\(;W[eg]
    \\(;B[ic]
    \\(;W[id]
    \\(;B[jc]
    \\(;W[gg]
    \\(;B[he]
    \\(;W[hf]
    \\(;B[cb]
    \\(;W[db]
    \\(;B[ab]
    \\(;W[ba]
    \\(;B[ie]
    \\(;W[ge]
    \\(;B[jd]
    \\(;W[gf]
    \\(;B[ca]
    \\(;W[bf]
    \\(;B[be]
    \\(;W[nq]
    \\(;B[pn]
    \\(;W[oo]
    \\(;B[po]
    \\(;W[pr]
    \\(;B[qq]
    \\(;W[qf]
    \\(;B[jf]
    \\(;W[ke]
    \\(;B[je]
    \\(;W[nc]
    \\(;B[oe]
    \\(;W[qc]
    \\(;B[pc]
    \\(;W[qd]
    \\(;B[pg]
    \\(;W[qg]
    \\(;B[ph]
    \\(;W[pe]
    \\(;B[pf]
    \\(;W[qe]
    \\(;B[ob]
    \\(;W[od]
    \\(;B[nb]
    \\(;W[ne]
    \\(;B[of]
    \\(;W[nf]
    \\(;B[qh]
    \\(;W[qb]
    \\(;B[mc]
    \\(;W[nh]
    \\(;B[jh]
    \\(;W[nj]
    \\(;B[pj]
    \\(;W[pk]
    \\(;B[qk]
    \\(;W[ok]
    \\(;B[ql]
    \\(;W[qj]
    \\(;B[rj]
    \\(;W[nm]
    \\(;B[mi]
    \\(;W[ni]
    \\(;B[fq]
    \\(;W[hq]
    \\(;B[fh]
    \\(;W[fg]
    \\(;B[cq]
    \\(;W[dq]
    \\(;B[cp]
    \\(;W[do]
    \\(;B[dr]
    \\(;W[er]
    \\(;B[cr]
    \\(;W[fr]
    \\(;B[cn]
    \\(;W[cl]
    \\(;B[cm]
    \\(;W[dl]
    \\(;B[mo]
    \\(;W[lp]
    \\(;B[mm]
    \\(;W[pm]
    \\(;B[qm]
    \\(;W[ml]
    \\(;B[np]
    \\(;W[oq]
    \\(;B[op]
    \\(;W[lm]
    \\(;B[lo]
    \\(;W[kp]
    \\(;B[ko]
    \\(;W[jp]
    \\(;B[jo]
    \\(;W[io]
    \\(;B[in]
    \\(;W[mn]
    \\(;B[ho]
    \\(;W[ip]
    \\(;B[en]
    \\(;W[em]
    \\(;B[dn]
    \\(;W[fp]
    \\(;B[cg]
    \\(;W[ch]
    \\(;B[bg]
    \\(;W[bh]
    \\(;B[qr]
    \\(;W[mp]
    \\(;B[on]
    \\(;W[nn]
    \\(;B[no]
    \\(;W[kg]
    \\(;B[jg]
    \\(;W[hi]
    \\(;B[fl]
    \\(;W[fm]
    \\(;B[hl]
    \\(;W[gl]
    \\(;B[gk]
    \\(;W[gm]
    \\(;B[hj]
    \\(;W[fj]
    \\(;B[fk]
    \\(;W[ej]
    \\(;B[kl]
    \\(;W[km]
    \\(;B[jm]
    \\(;W[li]
    \\(;B[kh]
    \\(;W[lh]
    \\(;B[le]
    \\(;W[kf]
    \\(;B[md]
    \\(;W[lf]
    \\(;B[me]
    \\(;W[mf]
    \\(;B[kj]
    \\(;W[kd]
    \\(;B[kc]
    \\(;W[nd]
    \\(;B[lj]
    \\(;W[mj]
    \\(;B[ii]
    \\(;W[hh]
    \\(;B[bl]
    \\(;W[bk]
    \\(;B[bm]
    \\(;W[qs]
    \\(;B[rs]
    \\(;W[ps]
    \\(;B[pq]
    \\(;W[or]
    \\(;B[ak]
    \\(;W[bj]
    \\(;B[gp]
    \\(;W[gq]
    \\(;B[fo]
    \\(;W[ep]
    \\(;B[rr]
    \\(;W[pb]
    \\(;B[oc]
    \\(;W[lc]
    \\(;B[lb]
    \\(;W[ld]
    \\(;B[mb]
    \\(;W[ga]
    \\(;B[hb]
    \\(;W[ag]
    \\(;B[cf]
    \\(;W[af]
    \\(;B[gj]
    \\(;W[da]
    \\(;B[aa]
    \\(;W[gi]
    \\(;B[ek]
    \\(;W[dk]
    \\(;B[hm]
    \\(;W[gn]
    \\(;B[go]
    \\(;W[hn]
    \\(;B[om]
    \\(;W[pl]
    \\(;B[ol]
    \\(;W[nl]
    \\(;B[oj]
    \\(;W[nk]
    \\(;B[rg]
    \\(;W[rf]
    \\(;B[rh]
    \\(;W[pi]
    \\(;B[qi]
    \\(;W[oi]
    \\(;B[sf]
    \\(;W[se]
    \\(;B[sg]
    \\(;W[sc]
    \\(;B[ae]
    \\(;W[ah]
    \\(;B[qj]
    \\(;W[co]
    \\(;B[bo]
    \\(;W[aj]
    \\(;B[og]
    \\(;W[lk]
    \\(;B[kk]
    \\(;W[ki]
    \\(;B[ji]
    \\(;W[al]
    \\(;B[am]
    \\(;W[kn]
    \\(;B[jn]
    \\(;W[ha]
    \\(;B[ia]
    \\(;W[fa]
    \\(;B[ll]
    \\(;W[ln]
    \\(;B[ng]
    \\(;W[mg]
    \\(;B[es]
    \\(;W[fs]
    \\(;B[ds]
    \\(;W[hc]
    \\(;B[ib]
    \\(;W[oa]
    \\(;B[na]
    \\(;W[pa]
    \\(;B[eo]
    \\(;W[eq]
    \\(;B[ig]
    \\(;W[mk]
    \\(;B[hg]
    \\(;W[dj]
    \\(;B[ak]
    \\(;W[dg]
    \\(;B[al]
    \\(;W[hp]
    \\(;B[bp]
    \\(;W[dm]
    \\(;B[fn]
    \\(;W[el]
    \\(;B[oh]
    \\(;W[cc]
    \\(;B[cd]
    \\(;W[df]
    \\(;B[if]
    \\(;W[ih]
    \\(;B[]
    \\(;W[]
    \\C[saucepan: gg
    \\GeRui: thank you
    \\]
    \\))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
;

const Rgb = struct {
    r: u8,
    g: u8,
    b: u8,
};

fn toByte(v: u4) u8 {
    return @as(u8, v) * 0x10 + v;
}

const hex1 = mecha.int(u4, .{
    .parse_sign = false,
    .base = 16,
    .max_digits = 1,
}).map(toByte);
const hex2 = mecha.int(u8, .{
    .parse_sign = false,
    .base = 16,
    .max_digits = 2,
});
const rgb1 = mecha.manyN(hex1, 3, .{});
const rgb2 = mecha.manyN(hex2, 3, .{});
const rgb = mecha.combine(.{
    mecha.ascii.char('#'),
    mecha.oneOf(.{ rgb2, rgb1 }),
});

fn returnTrue(char: u8) bool {
    _ = char;
    return true;
}

const parseIgnoreWhitespace = mecha.many(mecha.ascii.whitespace, .{}).discard();

const parseCValueType = mecha.oneOf(.{
    // mecha.combine(.{
    //     mecha.ascii.char('\\'),
    //     mecha.ascii.char(']'),
    // }),
    mecha.ascii.not(mecha.ascii.char(']')),
});

const parsePropValue = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char('[').discard(),
    mecha.asStr(mecha.many(parseCValueType, .{})),
    mecha.ascii.char(']').discard(),
    parseIgnoreWhitespace,
});

const parsePropIdent = mecha.combine(.{
    mecha.asStr(mecha.many(mecha.ascii.upper, .{ .min = 1 })),
});

const rawPropertyStruct = struct {
    ident: []void,
    // values: ,
};

const parseProperty = mecha.combine(.{
    parseIgnoreWhitespace,
    parsePropIdent,
    parseIgnoreWhitespace,
    mecha.many(parsePropValue, .{ .min = 1 }),
    parseIgnoreWhitespace,
});

fn parsedPropertyToStruct(result: anytype) rawPropertyStruct {
    return .{
        .ident = result[0],
        // .values = result[1:],
    };
}

const parseNode = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char(';').discard(),
    parseIgnoreWhitespace,
    mecha.many(parseProperty, .{}),
    // mecha.many(parseProperty.map(parsedPropertyToStruct), .{}),
    parseIgnoreWhitespace,
});

const parseSequence = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.many(parseNode, .{ .min = 1 }),
    parseIgnoreWhitespace,
});

const parseGameTree = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char('(').discard(),
    parseIgnoreWhitespace,
    parseSequence,
    parseIgnoreWhitespace,
    mecha.ascii.char(')').discard(),
    parseIgnoreWhitespace,
});

const rawGameTreeStruct = struct {
    game_tree: []void,
};

fn parsedGameTreeToStruct(result: anytype) rawGameTreeStruct {
    return .{
        .game_tree = &result,
    };
}

// const RawGameTree = struct {};

// const RawNode = struct {};

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const allocator: std.mem.Allocator = init.arena.allocator();

    const a = (try rgb.parse(allocator, "#aabbcc")).value.ok;
    std.debug.print("{any}\n", .{a});

    const parsedSgf = (try parseGameTree.parse(allocator, example_fragment)).value.ok;
    std.debug.print("{any}\n", .{parsedSgf});

    // inline for (parsedSgf) |item| {
    //     std.debug.print("{any}\n", .{item});
    // }

    // const parsedSgf = (try parseGameTree.parse(allocator, example_fragment));
    // std.debug.print("{any}\n", .{parsedSgf});

    // const b = (try rgb.parse(allocator, "#abc")).value.ok;
    // std.debug.print("{} {} {}\n", .{ b.r, b.g, b.b });

    // const c = (try rgb.parse(allocator, "#000000")).value.ok;
    // std.debug.print("{} {} {}\n", .{ c.r, c.g, c.b });

    // const d = (try rgb.parse(allocator, "#000")).value.ok;
    // std.debug.print("{} {} {}\n", .{ d.r, d.g, d.b });
}
