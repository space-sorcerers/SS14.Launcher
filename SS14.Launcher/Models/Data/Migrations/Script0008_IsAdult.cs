using Microsoft.Data.Sqlite;

namespace SS14.Launcher.Models.Data.Migrations;

public sealed class Script0008_IsAdult : Migrator.IMigrationScript
{
    public string Up(SqliteConnection connection)
    {
        return "ALTER TABLE Login ADD COLUMN IsAdult INTEGER NOT NULL DEFAULT 1;";
    }
}
