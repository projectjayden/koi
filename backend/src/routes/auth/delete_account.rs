use crate::guards::auth::AuthenticatedUser;
use crate::guards::revoke_jwt::RevokeJWT;
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use rocket::http::Status;
use crate::utils::db::Db;

/// # Delete Account
/// **Route**: /auth/delete-account
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// - 200 (success)
#[get("/delete-account")]
pub async fn delete_account(mut db: Connection<Db>, user: AuthenticatedUser, _revoke_jwt: RevokeJWT) -> Status {
  sqlx::query("DELETE FROM users WHERE uuid = $1").bind(&user.0.uuid).execute(&mut **db).await.unwrap();

  Status::Ok
}
