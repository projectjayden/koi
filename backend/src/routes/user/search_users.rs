use crate::{ guards::auth::AuthenticatedUser, models::users::user::MiniUser };
use rocket_db_pools::{ sqlx::{ self, sqlite::SqliteRow }, Connection };
use crate::utils::{ db::Db, functions::get_from_row };
use rocket::serde::{ json::Json, Deserialize };

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct SearchInput {
  /// Number of reviews to get.
  ///
  /// Defaults to `20`.
  pub limit: Option<u32>,
  /// Offset of reviews.
  ///
  /// Defaults to `0`.
  pub offset: Option<u32>,
}

/// # Search Users by Name
///
/// **Route**: /user/search/<name>
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   limit?: number;
///   offset?: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// [
///   number, // total users found
///   {
///     uuid: string;
///     name: string;
///     bio: string | null;
///     isSubscribed: boolean;
///     followers: number;
///     following: number;
///   }[]; // users
/// ]
/// ```
#[post("/search/<name>", data = "<data>")]
pub async fn search_users(mut db: Connection<Db>, user: AuthenticatedUser, name: &str, data: Json<SearchInput>) -> Json<(usize, Vec<MiniUser>)> {
  let total_users: (u32,) = sqlx
    ::query_as("SELECT COUNT(*) FROM users WHERE name LIKE $1 AND store_uuid IS NULL AND uuid != $2")
    .bind(format!("%{}%", name))
    .bind(user.0.uuid)
    .fetch_one(&mut **db).await
    .unwrap();

  let user_uuids: Vec<String> = sqlx
    ::query("SELECT uuid FROM users WHERE name LIKE $1 LIMIT $2 OFFSET $3")
    .bind(format!("%{}%", name))
    .bind(data.0.limit.unwrap_or(20))
    .bind(data.0.offset.unwrap_or(0))
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

  Json((total_users.0 as usize, users))
}
