const std = @import("std");
const httpz = @import("httpz");
// const datastar = @import("datastar").httpz;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();
    defer (switch (gpa.deinit()) {
        .leak => std.debug.print("Leak !\n", .{}),
        .ok => std.debug.print("Shutdown OK\n", .{}),
    });

    var app = App{};

    var server = try httpz.Server(*App).init(allocator, .{ .port = 8081 }, &app);
    var router = try server.router(.{});
    router.get("/", index, .{});
    router.get("/hello", hello, .{});
    // router.get("/hello", helloWorld, .{});
    // router.get("/bind", bind, .{});
    std.debug.print("Starting DataStar test app on http://localhost:8081\n", .{});
    try server.listen();
}

const App = struct {};

fn serveFile(filename: []const u8, arena: std.mem.Allocator, res: *httpz.Response) !void {
    errdefer {
        res.status = 404;
        res.body = "Not found";
    }

    // If the file exists in the public dir, then send it !
    const dir = try std.fs.cwd().openDir("www", .{});
    const file = try dir.openFile(filename, .{});
    defer file.close();

    res.body = try file.readToEndAlloc(arena, 1_000_000);
}

pub fn fileServe(_: *App, req: *httpz.Request, res: *httpz.Response) !void {
    return serveFile(req.url.path[1..], req.arena, res);
}

fn index(_: *App, req: *httpz.Request, res: *httpz.Response) !void {
    return serveFile("index.html", req.arena, res);
}

pub fn readSignals(comptime T: type, req: *httpz.Request) !T {
    switch (req.method) {
        .GET => {
            const query = try req.query();
            const signals = query.get("datastar") orelse return error.MissingDatastarKey;
            std.debug.print("got datastar param {s}\n", .{signals});

            return std.json.parseFromSliceLeaky(T, req.arena, signals, .{});
        },
        else => {
            const body = req.body() orelse return error.MissingBody;

            return std.json.parseFromSliceLeaky(T, req.arena, body, .{});
        },
    }
}

// fn helloWorld(_: *App, req: *httpz.Request, res: *httpz.Response) !void {
//     var sse = try datastar.ServerSentEventGenerator.init(res);
//     const signals = try datastar.readSignals(
//         Signals,
//         req,
//     );

//     inline for (message, 0..) |_, i| {
//         const fragment = std.fmt.comptimePrint(
//             "<div id='message'>{s}</div>",
//             .{message[0 .. i + 1]},
//         );
//         try sse.mergeFragments(fragment, .{});

//         std.Thread.sleep(std.time.ns_per_ms * signals.delay);
//     }
// }

const message = "Hello, world!";
const HelloContext = struct {
    delay: u64 = 1000,

    fn handle(self: HelloContext, stream: std.net.Stream) void {
        std.debug.print("in the handler with delay {}\n", .{self.delay});
        const w = stream.writer();
        w.print("event: datastar-merge-fragments\n", .{}) catch return;
        inline for (message, 0..) |_, i| {
            const fragment = std.fmt.comptimePrint(
                "<div id='message'>{s}</div>",
                .{message[0 .. i + 1]},
            );
            w.print("data: {s}\n", .{fragment}) catch return;

            std.Thread.sleep(std.time.ns_per_ms * self.delay);
        }
        w.writeAll("\n\n") catch return;
    }
};

fn hello(_: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const ctx = try readSignals(HelloContext, req);
    std.debug.print("parsed a hello context with delay {}\n", .{ctx.delay});
    try res.startEventStream(ctx, HelloContext.handle);
}
