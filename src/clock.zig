const Clock = @This();

ticks: usize = 0,

// Calling the clock handler sets up a permanent SSE connection
// that is subscribed to the global clock that updates every second
//
// See app.zig -> clock() function that generates output to all clock subscribers
// by calling this render() function below
pub fn handler(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    _ = req;
    app.call_count += 1;

    const stream = try res.startEventStreamSync();
    const id = try app.clockSubscribers.add(stream);
    std.debug.print("added new clock subscriber {} ... and leaving this connection open but closing the thread\n", .{id + 1});
}

pub fn increment(self: *Clock) void {
    self.ticks += 1;
}

// render is the callback that the app calls every second on this clock
// object, for each subscriber
pub fn render(self: *Clock, id: usize, stream: std.net.Stream) !void {
    var frag = MergeFragments.init(stream);
    try frag.writer().print("<div id='clock' data-subscriber='{}'>{}</div>", .{ id, self.ticks });
    frag.endFragment();
}

const std = @import("std");
const httpz = @import("httpz");

const App = @import("app.zig");
const MergeFragments = @import("merge_fragments.zig");
