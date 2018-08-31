/// SQLite specific `SQLDropIndex`.
public struct SQLiteDropIndex: SQLDropIndex {
    /// See `SQLDropIndex`.
    public var identifier: SQLiteIdentifier
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable], aliases: SQLTableAliases?) -> String {
        var sql: [String] = []
        sql.append("DROP INDEX")
        sql.append(identifier.serialize(&binds))
        return sql.joined(separator: " ")
    }
}

/// SQLite specific drop index builder.
public final class SQLiteDropIndexBuilder<Connection>: SQLQueryBuilder
    where Connection: SQLConnection, Connection.Query == SQLiteQuery
{
    /// `AlterTable` query being built.
    public var dropIndex: SQLiteDropIndex
    
    /// See `SQLQueryBuilder`.
    public var connection: Connection
    
    /// See `SQLQueryBuilder`.
    public var query: SQLiteQuery {
        return .dropIndex(dropIndex)
    }
    
    /// Creates a new `SQLCreateIndexBuilder`.
    public init(_ dropIndex: SQLiteDropIndex, on connection: Connection) {
        self.dropIndex = dropIndex
        self.connection = connection
    }
}


extension SQLConnection where Query == SQLiteQuery {
    /// Drops an index from a SQLite database.
    public func drop(index identifier: SQLiteIdentifier) -> SQLiteDropIndexBuilder<Self> {
        return .init(SQLiteDropIndex(identifier: identifier), on: self)
    }
}
