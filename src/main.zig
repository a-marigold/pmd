const std = @import("std");
const mem = std.mem;
const Io = std.Io;
const File = Io.File;
const process = std.process;
const heap = std.heap;
const builtin = @import("builtin");

const OS = builtin.target.os.tag;

const HELP_TEXT =
    \\Usage:
    \\  Read input from stdin
    \\    tmd << file.md
    \\    cat file.md | tmd
    \\
    \\  --help Show this help
;

const Errors = struct {
    pub const UNKNOWN_ARG = "Unknown argument. Try '--help'";
};
pub fn main(init: process.Init.Minimal) !void {
    var threaded: Io.Threaded = .init(.failing, .{});
    const io = threaded.io();

    var args_iter = switch (OS) {
        .windows => block: {
            const gpa = heap.smp_allocator;
            break :block try init.args.iterateAllocator(gpa);
        },
        else => init.args.iterate(),
    };
    _ = args_iter.skip();

    const stdout_writer = block: {
        var buffer: [1024]u8 = undefined;

        var stdout_writer = File.stdout().writerStreaming(io, &buffer);
        break :block &stdout_writer.interface;
    };
    const stderr_writer = block: {
        // Unbuffered
        var stderr_writer = File.stdout().writerStreaming(io, &.{});
        break :block &stderr_writer.interface;
    };

    if (args_iter.next()) |arg| {
        if (mem.eql(u8, arg, "--help")) {
            _ = try stdout_writer.vtable.drain(stdout_writer, &.{HELP_TEXT}, 1);
            exit(.Success);
        }

        _ = try stderr_writer.vtable.drain(stderr_writer, &.{Errors.UNKNOWN_ARG}, 1);
        exit(.InvalidArgs);
    }
}

const ExitStatus = enum(u8) {
    Success,
    GeneralError,
    InvalidArgs,
};
inline fn exit(status: ExitStatus) noreturn {
    process.exit(@backingInt(status));
}
