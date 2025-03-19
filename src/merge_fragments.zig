const Self = @This();

stream: std.net.Stream,
started: bool = false,
// TODO - add any other options here, and apply them to the header

const Writer = std.io.Writer(
    *Self,
    anyerror,
    write,
);

pub fn init(stream: std.net.Stream) Self {
    return Self{ .stream = stream };
}

pub fn endFragment(self: *Self) void {
    if (self.started) {
        self.started = false;
        self.stream.writer().writeAll("\n\n") catch return;
    }
}

pub fn header(self: *Self) !void {
    try self.stream.writer().writeAll("event: datastar-merge-fragments\n");
    self.started = true;

    // TODO - add any other bits according to the options passed
}

pub fn write(self: *Self, bytes: []const u8) !usize {
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

pub fn writer(self: *Self) Writer {
    return .{ .context = self };
}

const std = @import("std");
const httpz = @import("httpz");
