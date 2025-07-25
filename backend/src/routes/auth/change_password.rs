use rocket::{ http::Status, serde::{ Serialize, Deserialize, json::Json } };
use crate::utils::{ db::Db, jwt::generate_jwt };
use crate::guards::auth::AuthenticatedUser;
use bcrypt::{ hash, verify, DEFAULT_COST };
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use zxcvbn::zxcvbn;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct ChangePasswordData<'r> {
  old_password: &'r str,
  new_password: &'r str,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct ChangePasswordReturn {
  token: String
}

/// # Change Password
/// **Route**: /auth/change-password
///
/// **Request method**: POST
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
pub async fn change_password(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<ChangePasswordData<'_>>) -> Result<Json<ChangePasswordReturn>, Status> {
  if !verify(data.old_password, &user.0.password).unwrap() {
    return Err(Status::Unauthorized);
  }

  let new_password_strength: zxcvbn::Entropy = zxcvbn(data.new_password, &[data.old_password, user.0.email.as_str()]);
  if new_password_strength.score() < zxcvbn::Score::Three {
    return Err(Status::BadRequest);
  }

  let new_hashed_password: String = hash(data.new_password, DEFAULT_COST).unwrap();
  sqlx::query("UPDATE users SET password = $1 WHERE uuid = $2").bind(new_hashed_password).bind(&user.0.uuid).execute(&mut **db).await.unwrap();
  Ok(Json(ChangePasswordReturn {
    token: generate_jwt(&user.0.uuid.clone()).unwrap()
  }))
}
