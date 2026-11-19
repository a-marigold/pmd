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
    \\    pmd << file.md
    \\    cat file.md | pmd
    \\
    \\  --help Show this help
    \\
    \\Styles:
    \\  Styles of Markdown elements can be changed
    \\  via environment variables below.
    \\  Variables contain ANSI escape sequences
    \\  to be applied to their elements.
    \\
    \\  Example:
    \\    PMD_HEADING=\e[1m
    \\    PMD_CODE=\e[37;40m
    \\    PMD_PARAGRAPH=...
    \\    PMD_LINK=\e[4;34m
    \\    PMD_STRONG=...
    \\    PMD_ITALIC=...
;

const Errors = struct {
    pub const UNKNOWN_ARG = "Unknown argument. Try '--help'";
};

pub fn main(init: process.Init.Minimal) !void {
    // `Io` functions with allocator aren't used here
    var threaded: Io.Threaded = .init(undefined, .{});
    const io = threaded.io();

    var arg_iter = switch (OS) {
        // Allocator only for windows
        .windows => block: {
            const gpa = heap.smp_allocator;
            break :block try init.args.iterateAllocator(gpa);
        },
        else => init.args.iterate(),
    };
    _ = arg_iter.skip();

    const stdout_writer = block: {
        var buffer: [1024]u8 = undefined;

        var writer = File.stdout().writerStreaming(io, &buffer);
        break :block &writer.interface;
    };
    const stderr_writer = block: {
        // Unbuffered
        var writer = File.stdout().writerStreaming(io, &.{});
        break :block &writer.interface;
    };

    if (arg_iter.next()) |arg| {
        if (mem.eql(u8, arg, "--help")) {
            try stdout_writer.writeAll(HELP_TEXT);
            try stdout_writer.flush();
            exit(.Success);
        }

        try stderr_writer.writeAll(Errors.UNKNOWN_ARG);
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
