#if os(Linux)
import CSQLite
#else
import SQLite3
#endif

/// A connection to a SQLite database, created by `SQLiteDatabase`.
///
///     let conn = try sqliteDB.newConnection(on: ...).wait()
///
/// Use this connection to execute queries on the database.
///
///     try conn.query("SELECT sqlite_version();").wait()
///
/// You can also build queries, using the available query builders.
///
///     let res = try conn.select()
///         .column(function: "sqlite_version", as: "version")
///         .run().wait()
///
public final class SQLiteConnection: BasicWorker, DatabaseConnection, DatabaseQueryable, SQLConnection {

    /// See `DatabaseConnection`.
    public typealias Database = SQLiteDatabase

    /// See `DatabaseConnection`.
    public var isClosed: Bool

    /// See `BasicWorker`.
    public let eventLoop: EventLoop

    /// See `DatabaseConnection`.
    public var extend: Extend

    /// Optional logger, if set queries should be logged to it.
    public var logger: DatabaseLogger?

    /// Reference to parent `SQLiteDatabase` that created this connection.
    /// This reference will ensure the DB stays alive since this connection uses
    /// it's C pointer handle.
    internal let database: SQLiteDatabase

    /// Create a new SQLite conncetion.
    internal init(database: SQLiteDatabase, on worker: Worker) {
        self.database = database
        self.eventLoop = worker.eventLoop
        self.extend = [:]
        self.isClosed = false
    }

    /// Returns an identifier for the last inserted row.
    public var lastAutoincrementID: Int64? {
        return sqlite3_last_insert_rowid(database.handle)
    }

    /// Returns the last error message, if one exists.
    internal var errorMessage: String? {
        guard let raw = sqlite3_errmsg(database.handle) else {
            return nil
        }
        return String(cString: raw)
    }

    /// See `SQLConnection`.
    public func decode<D>(_ type: D.Type, from row: [SQLiteColumn : SQLiteData], table: GenericSQLTableIdentifier<SQLiteIdentifier>?) throws -> D where D : Decodable {
        return try SQLiteRowDecoder().decode(D.self, from: row, table: table)
    }

    /// See `SQLConnection`.
    public func decode<D>(_ type: D.Type, from row: [SQLiteColumn : SQLiteData], table: GenericSQLTableIdentifier<SQLiteIdentifier>?, occurrence: UInt = 1) throws -> D where D : Decodable {
        guard let tableString = table?.identifier.string else {
            throw SQLiteError(problem: .error, reason: "Invalid table: \(String(describing: table)).", source: .capture())
        }
        let requested_row = row.filter { $0.key.table == tableString && $0.key.occurrence == occurrence }
        return try SQLiteRowDecoder().decode(D.self, from: requested_row, table: table)
    }

    /// Executes the supplied `SQLiteQuery` on the connection, calling the supplied closure for each row returned.
    ///
    ///     try conn.query("SELECT * FROM users") { row in
    ///         print(row)
    ///     }.wait()
    ///
    /// - parameters:
    ///     - query: `SQLiteQuery` to execute.
    ///     - onRow: Callback for handling each row.
    /// - returns: A `Future` that signals completion of the query.
    public func query(_ query: SQLiteQuery, _ onRow: @escaping ([SQLiteColumn: SQLiteData]) throws -> ()) -> Future<Void> {
        var binds: [Encodable] = []
        let sql = query.serialize(&binds, aliases: nil)
        let promise = eventLoop.newPromise(Void.self)
        let data = try! binds.map { try SQLiteDataEncoder().encode($0) }
        // log before anything happens, in case there's an error
        logger?.record(query: sql, values: data.map { $0.description })
        database.blockingIO.submit { state in
            do {
                let statement = try SQLiteStatement(query: sql, on: self)
                try statement.bind(data)
                if let columns = try statement.getColumns() {
                    while let row = try statement.nextRow(for: columns) {
                        self.eventLoop.execute {
                            do {
                                try onRow(row)
                            } catch {
                                promise.fail(error: error)
                            }
                        }
                    }
                }
                return promise.succeed(result: ())
            } catch {
                return promise.fail(error: error)
            }
        }
        return promise.futureResult
    }

    /// See `DatabaseConnection`.
    public func close() {
        isClosed = true
    }
}
