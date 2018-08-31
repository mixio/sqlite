// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SQLite",
    products: [
        .library(name: "SQLite", targets: ["SQLite"]),
    ],
    dependencies: [
        // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),

        // 🗄 Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", from: "1.2.0"),

        // *️⃣ Build SQL queries in Swift. Extensible, protocol-based design that supports DQL, DML, and DDL.
        .package(url: "https://github.com/mixio/sql.git", from: "table-aliases-and-resultset-occurrences"),
    ],
    targets: [
        .testTarget(name: "SQLiteTests", dependencies: ["SQLite", "SQLBenchmark"]),
    ]
)

#if os(Linux)
package.targets.append(.target(name: "CSQLite"))
package.targets.append(.target(name: "SQLite", dependencies: ["Async", "Bits", "Core", "CSQLite", "DatabaseKit", "Debugging", "SQL"]))
#else
package.targets.append(.target(name: "SQLite", dependencies: ["Async", "Bits", "Core", "DatabaseKit", "Debugging", "SQL"]))
#endif
