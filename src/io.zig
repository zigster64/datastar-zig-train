// This struct is an IO driver that presents a FIFO ring buffer
// and a single std.net.Stream to write to
//
// You can append data to be sent by writing to the FIFO
//
// A collection of these out_queue structs has an event loop
// that acts on it by waiting for CAN WRITE to be available
// then writing the contents of the FIFO buffer
//
// For short writes, the bytes that are not transmitted this
// kevent window are returned to the front of the FIFO ring buffer
// and will be re-transmitted when the socket is avail for write again

pub const Stream = struct {
    ctx: *anyopaque,
    gpa: std.mem.Allocator,
    stream: std.net.Stream,
    req: *httpz.Request,
    fifo: std.fifo.LinearFifo(u8, .Dynamic),
    mutex: std.Thread.Mutex = .{},

    pub fn init(gpa: std.mem.Allocator, ctx: *anyopaque, stream: std.net.Stream, req: *httpz.Request) Stream {
        return .{
            .ctx = ctx,
            .gpa = gpa,
            .stream = stream,
            .req = req,
            .fifo = std.fifo.LinearFifo(u8, .Dynamic).init(gpa),
        };
    }

    /// Cleanup resources (close the fd and free FIFO memory).
    pub fn deinit(self: *Stream) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.fifo.deinit();
        self.stream.close();
    }

    pub fn lock(self: *Stream) void {
        self.mutex.lock();
    }

    pub fn unlock(self: *Stream) void {
        self.mutex.unlock();
    }
};

pub const Streams = struct {
    gpa: std.mem.Allocator,
    streams: std.ArrayList(Stream),
    mutex: std.Thread.Mutex = .{},

    pub fn init(gpa: std.mem.Allocator) Streams {
        return .{
            .gpa = gpa,
            .streams = std.ArrayList(Stream).init(gpa),
        };
    }

    pub fn deinit(self: *Streams) void {
        for (self.streams.items) |s| {
            s.deinit();
        }
        self.streams.deinit();
    }

    // add a new stream, and return its unique id
    pub fn add(self: *Streams, ctx: *anyopaque, stream: std.net.Stream, req: *httpz.Request) !usize {
        self.mutex.lock();
        defer self.mutex.unlock();
        const index = self.streams.items.len;
        try self.streams.append(Stream.init(self.gpa, ctx, stream, req));
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

    pub fn get(self: *Streams, index: usize) ?Stream {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (index >= self.streams.items.len) return null;
        return self.streams.items[index];
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
