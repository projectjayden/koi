use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::{ sqlx, Connection };
use rocket::http::Status;
use crate::utils::db::Db;

/// # Like a Recipe
/// **Route**: /user/recipe/like/<uuid>
///
/// **Request method**: PUT
///
/// **Input**: None
///
/// **Output**:
/// - 200 (success)
/// - 400 (already liked)
/// - 404 (recipe not found)
#[put("/like/<uuid>")]
pub async fn like(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str) -> Status {
  let recipe_exists: bool = sqlx::query("SELECT * FROM recipes WHERE uuid = $1").bind(&uuid).fetch_one(&mut **db).await.is_ok();
  if !recipe_exists {
    return Status::NotFound;
  }

  let already_liked: bool = sqlx::query("SELECT * FROM recipes_liked WHERE user_uuid = $1 AND recipe_uuid = $2").bind(&user.0.uuid).bind(&uuid).fetch_one(&mut **db).await.is_ok();
  if already_liked {
    return Status::BadRequest;
  }

  sqlx::query("INSERT INTO recipes_liked (user_uuid, recipe_uuid) VALUES ($1, $2)").bind(user.0.uuid).bind(uuid).execute(&mut **db).await.unwrap();
  Status::Ok
}
