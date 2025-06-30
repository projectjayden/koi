use rocket::{ http::{ CookieJar, Status }, serde::{ Deserialize, json::Json } };
use crate::{ utils::{ db::Db, functions::{ create_cookie, get_unix_seconds } } };
use bcrypt::{ DEFAULT_COST, hash };
use rocket_db_pools::sqlx::{ self, Row };
use rocket_db_pools::Connection;
use zxcvbn::zxcvbn;
use uuid::Uuid;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct SignupData<'r> {
  email: &'r str,
  password: &'r str,
}

/// # Signup
/// **Route**: /auth/signup
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
/// - 201 (success)
/// - 400 (password too weak)
/// - 401 (email already used)
/// - 500 (error)
#[post("/signup", format = "json", data = "<data>")]
pub async fn signup(mut db: Connection<Db>, cookies: &CookieJar<'_>, data: Json<SignupData<'_>>) -> Status {
  let password_strength: zxcvbn::Entropy = zxcvbn(data.password, &[data.email]);
  if password_strength.score() < zxcvbn::Score::Three {
    return Status::BadRequest;
  }

  let email_in_db: Option<sqlx::sqlite::SqliteRow> = sqlx::query("SELECT * FROM users WHERE email = ?").bind(data.email).fetch_one(&mut **db).await.ok();
  if let Some(_) = email_in_db {
    return Status::Unauthorized;
  }

  let hashed_password: String = hash(data.password, DEFAULT_COST).unwrap();

  let result: Option<String> = sqlx
    ::query("INSERT INTO users (uuid, password, last_login, email, date_joined) VALUES (?, ?, ?, ?, ?) RETURNING uuid")
    .bind(Uuid::new_v4().to_string())
    .bind(&hashed_password)
    .bind(get_unix_seconds() as u32)
    .bind(data.email)
    .bind(get_unix_seconds() as u32)
    .fetch_one(&mut **db).await
    .and_then(|row: sqlx::sqlite::SqliteRow| Ok(row.try_get::<String, _>("uuid").unwrap()))
    .ok();

  match result {
    Some(uuid) => {
      cookies.add_private(create_cookie("auth_token", uuid));

      Status::Ok
    }
    None => Status::InternalServerError,
  }
}
