use crate::{ guards::auth::AuthenticatedUser };
use rocket::{ http::{ CookieJar, Status }, serde::{ Deserialize, json::Json } };
use crate::{ utils::{ db::Db, functions::create_cookie } };
use rocket_db_pools::sqlx;
use rocket_db_pools::Connection;
use zxcvbn::zxcvbn;
use bcrypt::{ hash, verify, DEFAULT_COST };

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct ChangePasswordData<'r> {
  old_password: &'r str,
  new_password: &'r str,
}

/// # Change Password
/// **Route**: /auth/change-password
///
/// **Request method**: GET
///
/// **Input**:
/// ```ts
/// {
///   old_password: string;
///   new_password: string;
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
/// - 400 (password too weak)
/// - 401 (old password wrong)
#[post("/change-password", format = "json", data = "<data>")]
pub async fn change_password(mut db: Connection<Db>, cookies: &CookieJar<'_>, user: AuthenticatedUser, data: Json<ChangePasswordData<'_>>) -> Status {
  if verify(data.old_password, &user.0.password).unwrap() == false {
    return Status::Unauthorized;
  }

  let new_password_strength: zxcvbn::Entropy = zxcvbn(data.new_password, &[data.old_password, user.0.email.as_str()]);
  if new_password_strength.score() < zxcvbn::Score::Three {
    return Status::BadRequest;
  }

  sqlx::query("UPDATE users SET password = ? WHERE uuid = ?").bind(hash(data.new_password, DEFAULT_COST).unwrap()).bind(&user.0.uuid).execute(&mut **db).await.unwrap();
  cookies.add_private(create_cookie("auth_token", user.0.uuid.clone()));

  Status::Ok
}
