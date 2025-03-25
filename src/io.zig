pub const Streams = struct {
    gpa: std.mem.Allocator,
    streams: std.ArrayList(std.net.Stream),
    mutex: std.Thread.Mutex = .{},

    pub fn init(gpa: std.mem.Allocator) Streams {
        return .{
            .gpa = gpa,
            .streams = std.ArrayList(std.net.Stream).init(gpa),
        };
    }

    pub fn deinit(self: *Streams) void {
        for (self.streams.items) |s| {
            s.deinit();
        }
        self.streams.deinit();
    }

    // add a new stream, and return its unique id
    pub fn add(self: *Streams, stream: std.net.Stream) !usize {
        self.mutex.lock();
        defer self.mutex.unlock();
        const index = self.streams.items.len;
        try self.streams.append(stream);
        return index;
    }

    pub fn remove(self: *Streams, index: usize) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (index < self.streams.items.len) {
            const stream = self.streams.items[index];
            stream.deinit();
            self.streams.swapRemove(index);
        }
    }

    pub fn lock(self: *Streams) void {
        self.mutex.lock();
    }

    pub fn unlock(self: *Streams) void {
        self.mutex.unlock();
    }
};

const std = @import("std");
const httpz = @import("httpz");
