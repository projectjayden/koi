use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::{ sqlx, Connection };
use rocket::serde::json::Json;
use crate::utils::db::Db;

/// # Check If User is Following
/// Checks if the current user is following the user with the given uuid
///
/// **Route**: /user/is-following/<uuid>
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**: `boolean` - `true` if user is following, `false` if not
#[get("/is-following/<uuid>")]
pub async fn is_following(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str) -> Json<bool> {
  let user_is_following: bool = sqlx::query("SELECT follower_uuid FROM followers WHERE follower_uuid = $1 AND following_uuid = $2").bind(user.0.uuid).bind(&uuid).fetch_one(&mut **db).await.is_ok();

  Json(user_is_following)
}
