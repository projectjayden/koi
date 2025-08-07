use crate::{ guards::auth::AuthenticatedUser, utils::functions::get_unix_seconds };
use rocket::serde::json::{ Json, to_string };
use rocket_db_pools::{ sqlx, Connection };
use crate::utils::db::Db;

/// # Create a List
/// **Route**: /user/list/create
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// string[]; // item UUIDs
/// ```
///
/// **Output**: `string` - The list's UUID
#[post("/create", data = "<data>")]
pub async fn create(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<Vec<String>>) -> String {
  let uuid: String = uuid::Uuid::new_v4().to_string();

  sqlx
    ::query("INSERT INTO lists (uuid, user_uuid, created_at, last_updated, items) VALUES ($1, $2, $3, $3, $4)")
    .bind(&uuid)
    .bind(&user.0.uuid)
    .bind(get_unix_seconds() as u32)
    .bind(to_string(&data.0).unwrap())
    .execute(&mut **db).await
    .unwrap();

  uuid
}
