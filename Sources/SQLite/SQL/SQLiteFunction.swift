/// SQLite specific `SQLFunction`.
public struct SQLiteFunction: SQLFunction {
    /// See `SQLFunction`.
    public typealias Argument = GenericSQLFunctionArgument<SQLiteExpression>
    
    /// `COUNT(*)`.
    public static var count: SQLiteFunction {
        return .init(name: "COUNT", arguments: [.all])
    }
    
    /// See `SQLFunction`.
    public static func function(_ name: String, _ args: [Argument]) -> SQLiteFunction {
        return .init(name: name, arguments: args)
    }
    
    /// See `SQLFunction`.
    public let name: String
    
    /// See `SQLFunction`.
    public let arguments: [Argument]
    
    /// See `SQLSerializable`.
    public func serialize(_ binds: inout [Encodable], aliases: SQLTableAliases?) -> String {
        return name + "(" + arguments.map { $0.serialize(&binds, aliases: aliases) }.joined(separator: ", ") + ")"
    }
}

extension SQLSelectExpression where Expression.Function == SQLiteFunction, Identifier == SQLiteIdentifier {
    /// `COUNT(*) as ...`.
    public static func count(as alias: SQLiteIdentifier? = nil) -> Self {
        return .expression(.function(.count), alias: alias)
    }
}
