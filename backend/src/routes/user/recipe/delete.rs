use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use crate::guards::auth::AuthenticatedUser;
use rocket::http::Status;
use crate::utils::db::Db;

/// # Delete a Recipe
/// **Route**: /user/recipe/delete/<uuid>
///
/// **Request method**: GET
///
/// **Output**:
/// - 200 (success)
/// - 401 (recipe not owned)
#[get("/delete/<uuid>")]
pub async fn delete(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str) -> Status {
  let author_uuid: String = sqlx
    ::query("SELECT user_uuid FROM recipes WHERE uuid = $1")
    .bind(&uuid)
    .fetch_one(&mut **db).await
    .and_then(|row: SqliteRow| Ok(row.try_get::<String, _>("user_uuid").unwrap()))
    .unwrap();
  if author_uuid != user.0.uuid {
    return Status::Unauthorized;
  }

  sqlx::query("DELETE FROM recipes WHERE uuid = $1 AND user_uuid = $2").bind(uuid).bind(user.0.uuid).execute(&mut **db).await.unwrap();
  Status::Ok
}
