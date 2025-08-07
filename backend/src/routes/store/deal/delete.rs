use crate::guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use rocket::http::Status;
use crate::utils::db::Db;

/// # Delete a Deal
/// **Route**: /store/deal/delete/<uuid>
///
/// **Request method**: DELETE
///
/// **Output**:
/// - 200 (success)
/// - 401 (deal not owned)
/// - 404 (deal not found)
#[delete("/delete/<uuid>")]
pub async fn delete(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, uuid: &str) -> Status {
  let store_uuid: Option<String> = sqlx
    ::query("SELECT store_uuid FROM deals WHERE uuid = $1")
    .bind(&uuid)
    .fetch_one(&mut **db).await
    .and_then(|row: SqliteRow| Ok(row.try_get::<String, _>("store_uuid").unwrap()))
    .ok();
  if let None = store_uuid {
    return Status::NotFound;
  }

  let store_uuid: String = store_uuid.unwrap();
  if store_uuid != store.0.uuid {
    return Status::Unauthorized;
  }

  sqlx::query("DELETE FROM deals WHERE uuid = $1 AND store_uuid = $2").bind(uuid).bind(store.0.uuid).execute(&mut **db).await.unwrap();
  Status::Ok
}
