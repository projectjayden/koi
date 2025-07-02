use crate::guards::auth::AuthenticatedUser;
use rocket::http::{ CookieJar, Status };
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use crate::utils::db::Db;

/// # Delete Account
/// **Route**: /auth/delete-account
///
/// **Request method**: GET
///
/// **Input**: N/A
///
/// **Output**:
/// - 200 (success)
#[get("/delete-account")]
pub async fn delete_account(mut db: Connection<Db>, cookies: &CookieJar<'_>, user: AuthenticatedUser) -> Status {
  sqlx::query("DELETE FROM users WHERE uuid = ?").bind(&user.0.uuid).execute(&mut **db).await.unwrap();
  cookies.remove_private("auth_token");

  Status::Ok
}
