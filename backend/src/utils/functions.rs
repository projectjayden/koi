use std::time::{ SystemTime, UNIX_EPOCH };

/// Gets the current unix timestamp in seconds.
pub fn get_unix_seconds() -> u64 {
  SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs()
}

use rocket_db_pools::sqlx::{ self, sqlite::SqliteRow, Row, Sqlite };

pub fn get_from_row<'a, T: sqlx::Decode<'a, Sqlite> + sqlx::Type<Sqlite>>(row: &'a SqliteRow, column: &str) -> T {
  row.try_get::<T, _>(column).unwrap()
}
