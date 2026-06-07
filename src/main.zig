const std = @import("std");

const mecha = @import("mecha");

const Io = std.Io;

const zig_sgf = @import("zig_sgf");

const example_fragment =
    \\(;
    \\FF[4]
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
    \\GN[友谊赛]
    \\;B[pd]
    \\(;W[dp]
    \\C[GeRui: hi
    \\]
    \\))
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

const example_sgf_2 =
    \\(;GM[1]FF[4]CA[UTF-8]AP[GoPanda2.5.2-3]ST[1]
    \\SZ[19]HA[0]KM[0.5]
    \\PW[Andrius]WR[4d]PB[blit]BR[3d+]RE[W+17.5]DT[2020-01-21]PC[IGS-PandaNet]
    \\
    \\;B[pd]
    \\;W[pp]
    \\;B[cd]
    \\;W[dp]
    \\;B[fd]
    \\;W[cj]
    \\;B[fq]
    \\;W[dn]
    \\;B[qq]
    \\;W[pq]
    \\;B[qp]
    \\;W[po]
    \\;B[qo]
    \\;W[qn]
    \\;B[rn]
    \\;W[jp]
    \\;B[dq]
    \\;W[cq]
    \\;B[cr]
    \\;W[eq]
    \\;B[dr]
    \\;W[ep]
    \\;B[er]
    \\;W[bq]
    \\;B[hq]
    \\;W[jr]
    \\;B[qm]
    \\;W[pn]
    \\;B[qr]
    \\;W[nc]
    \\;B[qf]
    \\;W[hc]
    \\;B[fc]
    \\;W[jd]
    \\;B[pm]
    \\;W[om]
    \\;B[ol]
    \\;W[pl]
    \\;B[ql]
    \\;W[pk]
    \\;B[ok]
    \\;W[pj]
    \\;B[oj]
    \\;W[pi]
    \\;B[oi]
    \\;W[pg]
    \\;B[oh]
    \\;W[qg]
    \\;B[on]
    \\;W[nm]
    \\;B[nn]
    \\;W[mm]
    \\;B[mn]
    \\;W[ln]
    \\;B[lm]
    \\;W[ml]
    \\;B[ll]
    \\;W[mk]
    \\;B[mp]
    \\;W[mr]
    \\;B[lr]
    \\;W[mq]
    \\;B[ko]
    \\;W[lq]
    \\;B[kn]
    \\;W[lk]
    \\;B[lh]
    \\;W[jk]
    \\;B[pf]
    \\;W[og]
    \\;B[kj]
    \\;W[kk]
    \\;B[jm]
    \\;W[pb]
    \\;B[nd]
    \\;W[mg]
    \\;B[mh]
    \\;W[qc]
    \\;B[mc]
    \\;W[oc]
    \\;B[lg]
    \\;W[mf]
    \\;B[le]
    \\;W[lf]
    \\;B[kf]
    \\;W[me]
    \\;B[ke]
    \\;W[md]
    \\;B[kc]
    \\;W[lc]
    \\;B[jc]
    \\;W[kd]
    \\;B[ld]
    \\;W[mb]
    \\;B[lb]
    \\;W[mc]
    \\;B[ic]
    \\;W[id]
    \\;B[hd]
    \\;W[jf]
    \\;B[jg]
    \\;W[if]
    \\;B[ig]
    \\;W[hf]
    \\;B[gd]
    \\;W[hb]
    \\;B[ib]
    \\;W[kb]
    \\;B[il]
    \\;W[ik]
    \\;B[hk]
    \\;W[lo]
    \\;B[lp]
    \\;W[hj]
    \\;B[ij]
    \\;W[gk]
    \\;B[hl]
    \\;W[gj]
    \\;B[hg]
    \\;W[gf]
    \\;B[jj]
    \\;W[cf]
    \\;B[fm]
    \\;W[el]
    \\;B[pr]
    \\;W[or]
    \\;B[nq]
    \\;W[np]
    \\;B[op]
    \\;W[oq]
    \\;B[no]
    \\;W[nr]
    \\;B[ir]
    \\;W[iq]
    \\;B[hr]
    \\;W[gg]
    \\;B[kp]
    \\;W[ls]
    \\;B[kq]
    \\;W[kr]
    \\;B[rj]
    \\;W[ri]
    \\;B[qj]
    \\;W[qi]
    \\;B[be]
    \\;W[bf]
    \\;B[gh]
    \\;W[fh]
    \\;B[hh]
    \\;W[dd]
    \\;B[dc]
    \\;W[de]
    \\;B[gb]
    \\;W[ia]
    \\;B[fl]
    \\;W[ek]
    \\;B[br]
    \\;W[bc]
    \\;B[cc]
    \\;W[bd]
    \\;B[ce]
    \\;W[ae]
    \\;B[bb]
    \\;W[ab]
    \\;B[ad]
    \\;W[ac]
    \\;B[ba]
    \\;W[cb]
    \\;B[db]
    \\;W[ef]
    \\;B[aq]
    \\;W[bp]
    \\;B[ap]
    \\;W[ao]
    \\;B[ar]
    \\;W[bo]
    \\;B[em]
    \\;W[dm]
    \\;B[jq]
    \\;W[go]
    \\;B[gp]
    \\;W[fo]
    \\;B[ho]
    \\;W[hn]
    \\;B[in]
    \\;W[gn]
    \\;B[gl]
    \\;W[qk]
    \\;B[rk]
    \\;W[sj]
    \\;B[rl]
    \\;W[gi]
    \\;B[fk]
    \\;W[fj]
    \\;B[sk]
    \\;W[si]
    \\;B[ph]
    \\;W[qh]
    \\;B[ng]
    \\;W[nf]
    \\;B[nh]
    \\;W[of]
    \\;B[fe]
    \\;W[ff]
    \\;B[hi]
    \\;W[en]
    \\;B[np]
    \\;W[ps]
    \\;B[qs]
    \\;W[os]
    \\;B[ee]
    \\;W[hm]
    \\;B[im]
    \\;W[df]
    \\;B[ed]
    \\;W[ga]
    \\;B[fa]
    \\;W[jb]
    \\;B[ca]
    \\;W[af]
    \\;B[ha]
    \\;W[je]
    \\;B[kg]
    \\;W[ga]
    \\;B[js]
    \\;W[gc]
    \\;B[ha]
    \\;W[sm]
    \\;B[rm]
    \\;W[ga]
    \\;B[fb]
    \\;W[ks]
    \\;B[is]
    \\;W[he]
    \\;B[ha]
    \\;W[io]
    \\;B[hp]
    \\;W[ga]
    \\;B[fp]
    \\;W[fn]
    \\;B[ha]
    \\;W[ro]
    \\;B[rp]
    \\;W[ga]
    \\;B[aa]
    \\;W[ad]
    \\;B[oo]
    \\;W[ha]
    \\;B[ge]
    \\)
    \\
;

const example_sgf_3 =
    \\(;GM[1]FF[4]CA[UTF-8]AP[CGoban:3]ST[2]
    \\RU[AGA]SZ[19]KM[7.50]
    \\PW[White]PB[Black]
    \\;B[pd]
    \\;W[qc]
    \\;B[pc]
    \\;W[qd]
    \\(;B[qe]
    \\;W[re]
    \\;B[qf]
    \\;W[rf]
    \\;B[qg]
    \\(;W[pb]
    \\;B[ob]
    \\;W[qb]
    \\;B[nc])
    \\(;W[rg]
    \\;B[qh]
    \\;W[dp]
    \\;B[pb]
    \\;W[dd]
    \\;B[rb]
    \\;W[rh]
    \\;B[ri]
    \\;W[rc]
    \\(;B[sc]
    \\;W[sd]
    \\;B[sb]
    \\;W[qb]
    \\;B[qa]
    \\;W[rd]
    \\;B[ra]
    \\;W[rj])
    \\(;B[sd]
    \\;W[sc]
    \\;B[sh]
    \\;W[qb]
    \\;B[qa]
    \\;W[qi]
    \\;B[rj]
    \\;W[pi]
    \\;B[qk])))
    \\(;B[qf]
    \\(;W[rf]
    \\(;B[rg]
    \\;W[re]
    \\(;B[qg]
    \\;W[pb]
    \\;B[ob]
    \\;W[qb]
    \\;B[nc])
    \\(;B[pg]
    \\;W[pe]
    \\;B[qe]
    \\;W[pb]
    \\;B[ob]
    \\;W[qb]
    \\;B[nc]))
    \\(;B[pe]
    \\;W[rg]))
    \\(;W[qe]
    \\;B[pe]
    \\;W[rf]
    \\;B[qb]
    \\;W[rb]
    \\(;B[rg]
    \\;W[pb]
    \\;B[pf]
    \\;W[ob])
    \\(;B[re]
    \\(;W[rd]
    \\;B[rg]
    \\;W[se]
    \\;B[qg])
    \\(;W[pb]
    \\;B[rc]
    \\;W[qa]
    \\;B[rd]
    \\;W[qb]
    \\;B[rg]
    \\;W[pf]
    \\;B[qg]
    \\;W[nc]
    \\;B[nf]
    \\;W[ld]))))
    \\(;B[pe]
    \\;W[rf]))
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
    ident: []const u8,
    values: [][]const u8,
};

const parseProperty = mecha.combine(.{
    parseIgnoreWhitespace,
    parsePropIdent,
    parseIgnoreWhitespace,
    mecha.many(parsePropValue, .{ .min = 1 }),
    parseIgnoreWhitespace,
});

fn parsedPropertyToStruct(result: struct { []const u8, [][]const u8 }) rawPropertyStruct {
    return .{
        .ident = result[0],
        .values = result[1],
    };
}

const parseNode = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char(';').discard(),
    parseIgnoreWhitespace,
    // mecha.many(parseProperty, .{}),
    mecha.many(parseProperty.map(parsedPropertyToStruct), .{}),
    parseIgnoreWhitespace,
});

const rawNodeStruct = struct {
    properties: []rawPropertyStruct,
};
fn parsedNodeToStruct(result: []rawPropertyStruct) rawNodeStruct {
    return .{
        .properties = result,
    };
}

const parseSequence = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.many(parseNode.map(parsedNodeToStruct), .{ .min = 1 }),
    parseIgnoreWhitespace,
});

const rawSequenceStruct = struct {
    nodes: []rawNodeStruct,
};
fn parsedSequenceToStruct(result: []rawNodeStruct) rawSequenceStruct {
    return .{
        .nodes = result,
    };
}

const parseGameTree = mecha.combine(.{
    parseIgnoreWhitespace,
    mecha.ascii.char('(').discard(),
    parseIgnoreWhitespace,
    parseSequence.map(parsedSequenceToStruct),
    parseIgnoreWhitespace,
    mecha.many(mecha.ref(recursiveParseGameTree), .{}),
    parseIgnoreWhitespace,
    mecha.ascii.char(')').discard(),
    parseIgnoreWhitespace,
}).map(parsedGameTreeToStruct);
fn recursiveParseGameTree() mecha.Parser(rawGameTreeStruct) {
    return parseGameTree;
}

fn debugPrintNSpaces(num: u32) void {
    for (0..num) |_| {
        std.debug.print(" ", .{});
    }
}

const rawGameTreeStruct = struct {
    sequence: rawSequenceStruct,
    sub_game_trees: []rawGameTreeStruct,

    fn pretty_print(self: rawGameTreeStruct, extras: struct { depth: u32 = 0 }) void {
        debugPrintNSpaces(extras.depth * 2);
        std.debug.print("rawGameTreeStruct:\n", .{});
        for (self.sequence.nodes) |node| {
            debugPrintNSpaces(extras.depth * 2);
            std.debug.print("  Node:\n", .{});
            for (node.properties) |property| {
                debugPrintNSpaces(extras.depth * 2);
                std.debug.print("    {s} =", .{property.ident});
                for (property.values) |value| {
                    std.debug.print(" \"{s}\"", .{value});
                }
                std.debug.print("\n", .{});
            }
        }

        for (self.sub_game_trees) |sub_game_tree| {
            sub_game_tree.pretty_print(.{ .depth = extras.depth + 1 });
        }
    }
};
fn parsedGameTreeToStruct(result: struct { rawSequenceStruct, []rawGameTreeStruct }) rawGameTreeStruct {
    return .{
        .sequence = result[0],
        .sub_game_trees = result[1],
    };
}

pub fn main(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const allocator: std.mem.Allocator = init.arena.allocator();

    const io = init.io;
    const contents = try std.Io.Dir.readFileAlloc(
        try std.Io.Dir.cwd().openDir(io, "example-sgfs", .{}),
        io,
        "3-3_invasion_variations.sgf",
        allocator,
        .unlimited,
    );
    defer allocator.free(contents);

    const parsedSgf = (try parseGameTree.parse(allocator, contents)).value.ok;
    // std.debug.print("{any}\n", .{parsedSgf});

    parsedSgf.pretty_print(.{});
}
