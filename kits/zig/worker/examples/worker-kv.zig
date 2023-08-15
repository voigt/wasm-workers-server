const std = @import("std");
const io = std.io;
const http = std.http;
const worker = @import("worker");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

// Not working with *http.Server.Response
// fn cool(resp: *http.Server.Response, r: *http.Client.Request) void {
fn requestFn(resp: *worker.Response, r: *worker.Request) void {
    var cache = r.context.cache;
    var counter: i32 = 0;

    var v = cache.getOrPut("counter") catch undefined;

    if (!v.found_existing) {
        v.value_ptr.* = "0";
    } else {
        var counterValue = v.value_ptr.*;
        var num = std.fmt.parseInt(i32, counterValue, 10) catch undefined;
        counter = num + 1;
        var num_s = std.fmt.allocPrint(allocator, "{d}", .{ counter }) catch undefined;
        _ = cache.put("counter", num_s) catch undefined;
    }

    const s =
        \\<!DOCTYPE html>
        \\<head>
        \\<title>
        \\Wasm Workers Server - KV example</title>
        \\<meta name="viewport" content="width=device-width,initial-scale=1">
        \\<meta charset="UTF-8">
        \\</head>
        \\<body>
        \\<h1>Key / Value store in Zig</h1>
        \\<p>Counter: {d}</p>
        \\<p>This page was generated by a Zig⚡️ file running in WebAssembly.</p>
        \\</body>
    ;

    var body = std.fmt.allocPrint(allocator, s, .{ counter }) catch undefined; // add useragent

    _ = &resp.headers.append("x-generated-by", "wasm-workers-server");
    _ = &resp.writeAll(body);
}

pub fn main() !void {
    worker.ServeFunc(requestFn);
}
