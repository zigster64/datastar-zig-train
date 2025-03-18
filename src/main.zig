const std = @import("std");
const httpz = @import("httpz");

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
    std.debug.print("Starting DataStar test app on http://localhost:8081\n", .{});
    try server.listen();
}

const App = struct {};

pub fn fileServe(_: *App, req: *httpz.Request, res: *httpz.Response) !void {
    errdefer {
        res.status = 404;
        res.body = "Not found";
    }

    // If the file exists in the public dir, then send it !
    const dir = try std.fs.cwd().openDir("www", .{});
    const file = try dir.openFile(req.url.path[1..], .{});
    defer file.close();

    res.body = try file.readToEndAlloc(req.arena, 1_000_000);
}

fn index(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    _ = app;
    const dir = try std.fs.cwd().openDir("www", .{});
    const file = try dir.openFile("index.html", .{});
    defer file.close();
    res.body = try file.readToEndAlloc(req.arena, 1_000_000);
}
