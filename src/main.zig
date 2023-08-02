const std = @import("std");

const DirEntry = struct {
    const Self = @This();

    dir: std.fs.IterableDir,
    tree_index: usize,
    out_file: std.fs.File,

    fn new(out_file: std.fs.File, dir: std.fs.IterableDir, index: usize) Self {
        return Self{ .out_file = out_file, .dir = dir, .tree_index = index };
    }

    fn walk(self: *Self) !void {
        var iterator = self.dir.iterate();
        var next_entry = try iterator.next();

        while (next_entry) |entry| {
            for (0..self.tree_index) |_| {
                _ = try self.out_file.write("│   ");
            }

            next_entry = try iterator.next();
            if (next_entry != null) {
                _ = try self.out_file.write("├── ");
            } else {
                _ = try self.out_file.write("└── ");
            }
            _ = try self.out_file.write(entry.name);
            _ = try self.out_file.write("\n");
            if (entry.kind == .directory) {
                var dir = Self.new(self.out_file, try self.dir.dir.openIterableDir(entry.name, .{}), self.tree_index + 1);
                try dir.walk();
            }
        }

        self.dir.close();
    }
};

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    const dir = try std.fs.cwd().openIterableDir(".", std.fs.Dir.OpenDirOptions{});

    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    _ = gpa;

    var out_file = std.io.getStdOut();

    var e = DirEntry.new(out_file, dir, 0);
    try e.walk();

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
