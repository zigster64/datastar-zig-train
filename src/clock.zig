const Self = @This();

pub fn handler(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    _ = app;
    _ = req;
    var stream = try res.startEventStreamSync();
    var tick: i64 = 0;

    defer stream.close();
    while (true) {
        var frag = MergeFragments.init(stream);
        defer frag.endFragment();
        try frag.writer().print("<div id='clock'>{}</div>", .{tick});
        tick += 1;
        std.Thread.sleep(std.time.ns_per_s);
    }
}

const std = @import("std");
const httpz = @import("httpz");

const App = @import("app.zig");
const MergeFragments = @import("merge_fragments.zig");
