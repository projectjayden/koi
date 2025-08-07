use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use crate::guards::auth::AuthenticatedUser;
use rocket::http::Status;
use crate::utils::db::Db;

/// # Delete a List
/// **Route**: /user/list/delete/<uuid>
///
/// **Request method**: DELETE
///
/// **Output**:
/// - 200 (success)
/// - 401 (list not owned)
/// - 404 (list not found)
#[delete("/delete/<uuid>")]
pub async fn delete(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str) -> Status {
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

  sqlx::query("DELETE FROM lists WHERE uuid = $1 AND user_uuid = $2").bind(uuid).bind(user.0.uuid).execute(&mut **db).await.unwrap();
  Status::Ok
}
