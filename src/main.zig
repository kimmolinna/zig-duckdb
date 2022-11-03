const std = @import("std");
const dd = @cImport(@cInclude("duckdb.h"));

pub fn main() anyerror!void {
    const stdout = std.io.getStdOut().writer();
    var db: dd.duckdb_database = null;
    var con: dd.duckdb_connection = null;
    var result = dd.duckdb_result{
        .column_count = 0,
        .row_count = 0,
        .rows_changed = 0,
        .columns = 0,
        .error_message = 0,
        .internal_data = null
    };

    const path: [*]const u8 = ":memory:";

    if (dd.duckdb_open(path,&db) == dd.DuckDBError){
       try stdout.print("Failed to open database\n",.{});
       std.process.exit(1);
    }
    if (dd.duckdb_connect(db,&con) == dd.DuckDBError){
        try stdout.print("Failed to open connection\n",.{});
        std.process.exit(1); 
    }
    if (dd.duckdb_query(con, "CREATE TABLE integers(i INTEGER, j INTEGER);", null) == dd.DuckDBError){
        try stdout.print("Failed to query database\n",.{});
        std.process.exit(1); 
    }
    if (dd.duckdb_query(con, "INSERT INTO integers VALUES (3, 4), (5, 6), (7, NULL);", null) == dd.DuckDBError){
        try stdout.print("Failed to query database\n",.{});
        std.process.exit(1); 
    }
    if (dd.duckdb_query(con, "SELECT * FROM integers", &result) == dd.DuckDBError){
        try stdout.print("Failed to query database\n",.{});
        std.process.exit(1); 
    }

    // print the names of the result
    var i: usize = 0;
    while (i < dd.duckdb_column_count(&result)) : (i += 1) {
        try stdout.print("{s} ", .{dd.duckdb_column_name(&result, i)});
    }
    try stdout.print("\n",.{});

    // print the data of the result
    var row_idx: usize = 0;
    var col_idx: usize = 0;
    var val: [*c]u8 = null;

    while (row_idx < dd.duckdb_row_count(&result)) : (row_idx += 1) {
        col_idx = 0;
        while (col_idx < dd.duckdb_column_count(&result)) : (col_idx += 1) {
            val = dd.duckdb_value_varchar(&result, col_idx, row_idx);
            if (val==null){
                try stdout.print("  ", .{});               
            } else{
                try stdout.print("{s} ", .{val});   
            }
            dd.duckdb_free(val);
        }
        try stdout.print("\n",.{});
    }

    defer {
        dd.duckdb_destroy_result(&result);
        dd.duckdb_disconnect(&con);
        dd.duckdb_close(&db);
    }
}