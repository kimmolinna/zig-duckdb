const std = @import("std");
const dd = @import("duckdb");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    var db: dd.duckdb_database = null;
    var con: dd.duckdb_connection = null;
    var result: dd.duckdb_result = .{};

    const path: [*]const u8 = ":memory:";

    if (dd.duckdb_open(path, &db) == dd.DuckDBError) {
        try stdout.print("Failed to open database\n", .{});
        try stdout.flush();
        std.process.exit(1);
    }
    if (dd.duckdb_connect(db, &con) == dd.DuckDBError) {
        try stdout.print("Failed to open connection\n", .{});
        try stdout.flush();
        std.process.exit(1);
    }
    if (dd.duckdb_query(con, "CREATE TABLE integers(i INTEGER, j INTEGER);", null) == dd.DuckDBError) {
        try stdout.print("Failed to query database\n", .{});
        try stdout.flush();
        std.process.exit(1);
    }
    if (dd.duckdb_query(con, "INSERT INTO integers VALUES (3, 4), (5, 6), (7, NULL);", null) == dd.DuckDBError) {
        try stdout.print("Failed to query database\n", .{});
        try stdout.flush();
        std.process.exit(1);
    }
    if (dd.duckdb_query(con, "SELECT * FROM integers", &result) == dd.DuckDBError) {
        try stdout.print("Failed to query database\n", .{});
        try stdout.flush();
        std.process.exit(1);
    }

    try stdout.print("DuckDB {s}\n", .{dd.duckdb_library_version()});

    var i: usize = 0;
    while (i < dd.duckdb_column_count(&result)) : (i += 1) {
        try stdout.print("{s} ", .{dd.duckdb_column_name(&result, i)});
    }
    try stdout.print("\n", .{});

    var row_idx: usize = 0;
    while (row_idx < dd.duckdb_row_count(&result)) : (row_idx += 1) {
        var col_idx: usize = 0;
        while (col_idx < dd.duckdb_column_count(&result)) : (col_idx += 1) {
            const val = dd.duckdb_value_varchar(&result, col_idx, row_idx);
            if (val == null) {
                try stdout.print("  ", .{});
            } else {
                try stdout.print("{s} ", .{val});
            }
            dd.duckdb_free(val);
        }
        try stdout.print("\n", .{});
    }

    defer {
        dd.duckdb_destroy_result(&result);
        dd.duckdb_disconnect(&con);
        dd.duckdb_close(&db);
    }

    try stdout.flush();
}
