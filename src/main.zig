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
    router.get("/hello", HelloComponent.handler, .{});
    std.debug.print("Starting DataStar test app on http://localhost:8081\n", .{});
    try server.listen();
}

const App = struct {
    call_count: usize = 0,
};

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

// readSignals needs to be passed a req which looks like a httpz.Request
// must have req.method, req.query, and query.get
pub fn readSignals(comptime T: type, req: anytype) !T {
    switch (req.method) {
        .GET => {
            const query = try req.query();
            const signals = query.get("datastar") orelse return error.MissingDatastarKey;
            return std.json.parseFromSliceLeaky(T, req.arena, signals, .{});
        },
        else => {
            const body = req.body() orelse return error.MissingBody;
            return std.json.parseFromSliceLeaky(T, req.arena, body, .{});
        },
    }
}

const HelloComponent = struct {
    delay: u64 = 1000,
    something_else: u32 = 0,
    const message = "Hello, World! Hello Hello, Hello to the World!";

    fn handler(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
        app.call_count += 1;
        std.debug.print("Call number {d} in app\n", .{app.call_count});
        const self = try readSignals(HelloComponent, req);
        var stream = try res.startEventStream();

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
};

const MergeFragments = struct {
    stream: std.net.Stream,
    started: bool = false,
    // TODO - add any other options here, and apply them to the header

    const Writer = std.io.Writer(
        *MergeFragments,
        anyerror,
        write,
    );

    pub fn init(stream: std.net.Stream) MergeFragments {
        return MergeFragments{ .stream = stream };
    }

    pub fn endFragment(self: *MergeFragments) void {
        if (self.started) {
            self.started = false;
            self.stream.writer().writeAll("\n\n") catch return;
        }
    }

    pub fn header(self: *MergeFragments) !void {
        try self.stream.writer().writeAll("event: datastar-merge-fragments\n");
        self.started = true;
        // TODO - add any other bits according to the options passed
    }

    pub fn write(self: *MergeFragments, bytes: []const u8) !usize {
        if (!self.started) {
            try self.header();
        }

        var start: usize = 0;

        for (bytes, 0..) |b, i| {
            if (b == '\n') {
                try self.stream.writer().print("data: fragments {s}\n", .{bytes[start..i]});
                start = i + 1;
            }
        }

        if (start < bytes.len) {
            try self.stream.writer().print("data: fragments {s}\n", .{bytes[start..]});
        }

        return bytes.len;
    }

    pub fn writer(self: *MergeFragments) Writer {
        return .{ .context = self };
    }
};
