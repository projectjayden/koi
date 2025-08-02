use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::{ sqlx, Connection };
use rocket::http::Status;
use crate::utils::db::Db;

/// # Unlike a Recipe
/// **Route**: /user/recipe/unlike/<uuid>
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// - 200 (success)
#[get("/unlike/<uuid>")]
pub async fn unlike(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str) -> Status {
  sqlx
    ::query("DELETE FROM recipes_liked WHERE user_uuid = $1 AND recipe_uuid = $2")
    .bind(user.0.uuid)
    .bind(uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
