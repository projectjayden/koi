use crate::{ guards::auth::AuthenticatedUser, utils::functions::get_unix_seconds };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use rocket::{ http::Status, serde::json::{ Json, to_string } };
use super::create::{ ListInput, map_items };
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
/// - everything else from /user/list/create
#[patch("/edit/<uuid>", data = "<data>")]
pub async fn edit(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str, data: Json<ListInput>) -> Result<(), Status> {
  let author_uuid: Option<String> = sqlx
    ::query("SELECT user_uuid FROM lists WHERE uuid = $1")
    .bind(&uuid)
    .fetch_one(&mut **db).await
    .and_then(|row: SqliteRow| Ok(row.try_get::<String, _>("user_uuid").unwrap()))
    .ok();
  if let None = author_uuid {
    return Err(Status::NotFound);
  }

  let author_uuid: String = author_uuid.unwrap();
  if author_uuid != user.0.uuid {
    return Err(Status::Unauthorized);
  }

  let mapped_items: Vec<(u8, String)> = match map_items(&mut **db, data.0).await {
    Ok(mapped_items) => mapped_items,
    Err(status) => {
      return Err(status);
    }
  };

  sqlx
    ::query("UPDATE lists SET items = $1, last_updated = $2")
    .bind(to_string(&mapped_items).unwrap())
    .bind(get_unix_seconds() as u32)
    .execute(&mut **db).await
    .unwrap();

  Ok(())
}
