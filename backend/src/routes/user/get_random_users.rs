use crate::{ guards::auth::AuthenticatedUser, models::users::user::MiniUser };
use rocket_db_pools::{ sqlx::{ self, sqlite::SqliteRow }, Connection };
use crate::utils::{ db::Db, functions::get_from_row };
use rocket::serde::json::Json;

/// # Get Random Users
///
/// **Route**: /user/get-random-users/<limit>
/// Maximum limit of 100.
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// ```ts
/// {
///   uuid: string;
///   name: string;
///   bio: string | null;
///   isSubscribed: boolean;
///   followers: number;
///   following: number;
/// }[]; // users
/// ```
///
/// Can repeat users but we'll have a bajillion users one day for sure so its fine
#[get("/get-random-users/<limit>")]
pub async fn get_random_users(mut db: Connection<Db>, user: AuthenticatedUser, limit: u8) -> Json<Vec<MiniUser>> {
  let limit: u8 = if limit > 100 { 100 } else { limit };

  let user_uuids: Vec<String> = sqlx
    ::query("SELECT uuid FROM users WHERE ROWID IN (SELECT ROWID FROM users WHERE store_uuid IS NULL AND uuid != $1 ORDER BY RANDOM() LIMIT $2)")
    .bind(user.0.uuid)
    .bind(limit)
    .fetch_all(&mut **db).await
    .and_then(|rows: Vec<SqliteRow>|
      rows
        .into_iter()
        .map(|row: SqliteRow| Ok(get_from_row(&row, "uuid")))
        .collect()
    )
    .unwrap();

  let mut users: Vec<MiniUser> = vec![];

  for uuid in user_uuids {
    users.push(MiniUser::new(&mut db, uuid).await);
  }

  Json(users)
}
