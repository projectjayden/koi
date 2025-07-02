use rocket::{ http::{ CookieJar, Status }, serde::{ Deserialize, json::Json } };
use crate::utils::{ db::Db, functions::{create_cookie, get_unix_seconds} };
use rocket_db_pools::sqlx::{ self, Row };
use rocket_db_pools::Connection;
use bcrypt::verify;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct LoginData<'r> {
  email: &'r str,
  password: &'r str,
}

/// # Login
/// **Route**: /auth/login
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   email: string;
///   password: string;
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
/// - 401 (error)
#[post("/login", format = "json", data = "<data>")]
pub async fn login(mut db: Connection<Db>, cookies: &CookieJar<'_>, data: Json<LoginData<'_>>) -> Status {
  let user_data: Option<(String, String)> = sqlx
    ::query("UPDATE users SET last_login = ? WHERE email = ? RETURNING uuid, password")
    .bind(get_unix_seconds() as u32)
    .bind(data.email)
    .fetch_one(&mut **db).await
    .and_then(|row: sqlx::sqlite::SqliteRow| {
      let uuid: String = row.try_get::<String, _>("uuid").unwrap();
      let password: String = row.try_get::<String, _>("password").unwrap();
      Ok((uuid, password))
    })
    .ok();

  match &user_data {
    Some((_, hashed_password)) => {
      if !verify(data.password, hashed_password.as_str()).unwrap() {
        return Status::Unauthorized;
      }
    }
    None => {
      return Status::Unauthorized;
    }
  }

  let (uuid, _) = user_data.unwrap();
  cookies.add_private(create_cookie("auth_token", uuid));

  Status::Ok
}
