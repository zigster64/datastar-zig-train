# datastar-zig-train

Training app for learning Datastar ... and maybe updating the Zig SDK

## Hacks - Datastar SDK

Implemented a PoC of just the MergeFragments part of the Datastar SDK

This one presents a MergeFragments object that can provide a std Writer interface, that knows 
how to wrap its data as a D* MergeFragment protocol packet

Pretty simple

I might take this further (after this experiment), and do the same thing with the whole SDK

Also - implemented this using generics / anytype, so the resultant SDK shouldnt need to have 
any deps at all. The compiler should just work it out at comptime based on what type of 
req Object you pass to the SDK

## Hacks - http.zig modification

Small hack to the `req.startEventStream()` function - this now takes no params, and returns the stream
after setting it up for SSE, and writing the initial header

The returned stream is still in non-blocking mode

Actually seems to work !

## Hacks - Merge in Tardy (lib behind zzz)

Now, after the App code starts handling the /hello request with an SSE response, I want to 
hand this off to a coroutine, using the Tardy package

Interesting - because Tardy is derived from zzz, so we have come full circle here :)
