// A component that prints Hello World into the "message" div with a delay between each letter

delay: u64 = 1000,
something_else: u32 = 0,
const message = "Hello, World! Hello Hello, Hello to the World!";

const Self = @This();

// This is vanilla HTTP handler that holds the SSE connection open in the original
// thread, then writes to that socket with a delay
pub fn handler(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    app.call_count += 1;
    std.debug.print("Call number {d} in app\n", .{app.call_count});
    const self = try Datastar.readSignals(Self, req);
    var stream = try res.startEventStreamSync();

    defer stream.close();
    var frag = MergeFragments.init(stream);
    var w = frag.writer();
    inline for (message, 0..) |_, i| {
        // test a print to the frag writer
        try w.print("<div id='message'>{s}</div>", .{message[0 .. i + 1]});

        // add another update to the same fragment that updates a different part of the DOM
        // but still part of the same merge-fragment packet
        try w.print("<div id='count'>{}</div>", .{i});
        frag.endFragment();
        std.Thread.sleep(std.time.ns_per_ms * self.delay);
    }
}

pub fn handlerCoroutine(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    app.call_count += 1;
    std.debug.print("Call number {d} in app\n", .{app.call_count});
    const self = try Datastar.readSignals(Self, req);
    var stream = try res.startEventStreamSync();

    // TODO - spawn a coroutine to look after this !!
    defer stream.close();
    var frag = MergeFragments.init(stream);
    var w = frag.writer();
    inline for (message, 0..) |_, i| {
        // test a print to the frag writer
        w.print("<div id='message'>{s}</div>", .{message[0 .. i + 1]}) catch return;
        // add another update to the same fragment that updates a different part of the DOM
        // test multiple writes to the frag writer
        w.writeAll("<div id='count'>") catch return;
        w.print("Count={}", .{i}) catch return;
        w.writeAll("</div>") catch return;
        frag.endFragment();
        std.Thread.sleep(std.time.ns_per_ms * self.delay);
    }
}

const std = @import("std");
const httpz = @import("httpz");

const App = @import("app.zig");
const Datastar = @import("datastar.zig");
const MergeFragments = @import("merge_fragments.zig");
