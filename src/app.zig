// just a struct for the world / app state
// just tracking a call count for now - but you can add anything in here to map the global app state
// The global instance of this is passed as the Context param to all http handlers

call_count: usize = 0,
gpa: std.mem.Allocator = undefined,
clock: Clock,
clockSubscribers: io.Streams,

const App = @This();

pub fn init(gpa: std.mem.Allocator) App {
    return .{
        .gpa = gpa,
        .call_count = 0,
        .clock = .{},
        .clockSubscribers = io.Streams.init(gpa),
    };
}

pub fn runClock(app: *App) !void {
    var t = try std.Thread.spawn(.{}, tick, .{app});
    t.detach();
}

fn tick(app: *App) void {
    while (true) {
        std.time.sleep(1 * std.time.ns_per_s);
        std.debug.print("Global clock has ticked {}\n", .{app.clock.ticks});
        app.clock.increment();

        app.clockSubscribers.lock();
        defer app.clockSubscribers.unlock();

        const list = app.clockSubscribers.streams.items;

        // traverse the list backwards, so its safe to drop elements during the traversal
        var i: usize = list.len;
        while (i > 0) {
            i -= 1;
            var subscriber = list[i];
            app.clock.render(i + 1, subscriber) catch {
                // something failed writing to this sub, so unsub them
                std.debug.print("Closing subscriber {}\n", .{i + 1});
                subscriber.close();
                _ = app.clockSubscribers.streams.swapRemove(i);
            };
        }
    }
}

const std = @import("std");
const io = @import("io.zig");
const Clock = @import("clock.zig");
