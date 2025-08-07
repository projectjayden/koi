use crate::{ guards::auth::AuthenticatedUser, utils::functions::get_unix_seconds };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use rocket::{ http::Status, serde::json::{ Json, to_string } };
use crate::utils::db::Db;

/// # Edit a List
/// **Route**: /user/list/edit/<uuid>
///
/// **Request method**: PATCH
///
/// **Input**: Same as /user/list/create
///
/// **Output**:
/// - 200 (success)
/// - 401 (list not owned)
/// - 404 (list not found)
#[patch("/edit/<uuid>", data = "<data>")]
pub async fn edit(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str, data: Json<Vec<String>>) -> Status {
  let author_uuid: Option<String> = sqlx
    ::query("SELECT user_uuid FROM lists WHERE uuid = $1")
    .bind(&uuid)
    .fetch_one(&mut **db).await
    .and_then(|row: SqliteRow| Ok(row.try_get::<String, _>("user_uuid").unwrap()))
    .ok();
  if let None = author_uuid {
    return Status::NotFound;
  }

  let author_uuid: String = author_uuid.unwrap();
  if author_uuid != user.0.uuid {
    return Status::Unauthorized;
  }

  sqlx
    ::query("UPDATE lists SET items = $1, last_updated = $2")
    .bind(to_string(&data.0).unwrap())
    .bind(get_unix_seconds() as u32)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
