use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::{ sqlx, Connection };
use rocket::http::Status;
use crate::utils::db::Db;

/// # Follow a User
/// **Route**: /user/follow/<uuid>
///
/// **Request method**: PUT
///
/// **Input**: None
///
/// **Output**:
/// - 200 (success)
/// - 400 (already following)
/// - 418 (trying to follow self)
#[put("/follow/<uuid>")]
pub async fn follow(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str) -> Status {
  if uuid == user.0.uuid {
    return Status::ImATeapot;
  }

  let already_following: bool = sqlx::query("SELECT * FROM followers WHERE follower_uuid = $1 AND followed_uuid = $2").bind(&user.0.uuid).bind(&uuid).fetch_one(&mut **db).await.is_ok();
  if already_following {
    return Status::BadRequest;
  }

  sqlx::query("INSERT INTO followers (follower_uuid, followed_uuid) VALUES ($1, $2)").bind(user.0.uuid).bind(uuid).execute(&mut **db).await.unwrap();
  Status::Ok
}
