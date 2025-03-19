pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    const allocator = gpa.allocator();
    defer (switch (gpa.deinit()) {
        .leak => std.debug.print("Leak !\n", .{}),
        .ok => std.debug.print("Shutdown OK\n", .{}),
    });

    var app = App{};

    var server = try httpz.Server(*App).init(allocator, .{
        .port = 8081,
        .workers = .{ .min_conn = 4096, .max_conn = 8192 },
        .thread_pool = .{ .count = 4096 }, // lets have 4096 threads in the pool !!
    }, &app);
    var router = try server.router(.{});
    router.get("/", index, .{});
    router.get("/hello", HelloComponent.handler, .{});
    std.debug.print("Starting DataStar test app on http://localhost:8081\n", .{});
    try server.listen();
}

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

const std = @import("std");
const httpz = @import("httpz");

const App = @import("app.zig");
const HelloComponent = @import("hello.zig");
