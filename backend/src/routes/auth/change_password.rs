use rocket::{ http::Status, serde::{ Deserialize, json::Json } };
use crate::utils::{ db::Db, jwt::generate_jwt };
use crate::guards::auth::AuthenticatedUser;
use bcrypt::{ hash, verify, DEFAULT_COST };
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use zxcvbn::zxcvbn;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct ChangePasswordData {
  old_password: String,
  new_password: String,
}

/// # Change Password
/// **Route**: /auth/change-password
///
/// **Request method**: PATCH
///
/// **Input**:
/// ```ts
/// {
///   oldPassword: string;
///   newPassword: string;
/// }
/// ```
///
/// **Output**:
/// - `string` - New token (success)
/// - 400 (password too weak)
/// - 401 (old password wrong)
#[patch("/change-password", data = "<data>")]
pub async fn change_password(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<ChangePasswordData>) -> Result<String, Status> {
  if !verify(&data.old_password, &user.0.password).unwrap() {
    return Err(Status::Unauthorized);
  }

  let new_password_strength: zxcvbn::Entropy = zxcvbn(&data.new_password, &[&data.old_password, user.0.email.as_str()]);
  if new_password_strength.score() < zxcvbn::Score::Three {
    return Err(Status::BadRequest);
  }

  let new_hashed_password: String = hash(&data.new_password, DEFAULT_COST).unwrap();
  sqlx::query("UPDATE users SET password = $1 WHERE uuid = $2").bind(new_hashed_password).bind(&user.0.uuid).execute(&mut **db).await.unwrap();

  Ok(generate_jwt(&user.0.uuid.clone()).unwrap())
}
