use rocket::{ http::{ private::cookie::Expiration, Cookie, CookieJar, SameSite, Status }, time::OffsetDateTime, serde::{ Deserialize, json::Json } };

use crate::utils::{db::Db, functions::get_unix_seconds};
use bcrypt::{ DEFAULT_COST, hash, verify };
use zxcvbn::zxcvbn;
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx::{ self, Row };

fn create_cookie(name: &'static str, token: String) -> rocket::http::private::cookie::CookieBuilder<'static> {
  let one_week_from_now: i64 = (get_unix_seconds() + 86400 * 7).try_into().unwrap();
  let one_week_from_now: OffsetDateTime = OffsetDateTime::from_unix_timestamp(one_week_from_now).unwrap();
  let expiration: Expiration = Expiration::DateTime(one_week_from_now);

  // prettier-ignore
  Cookie::build((name, token))
    .path("/")
    .secure(true)
    .same_site(SameSite::Strict)
    .expires(expiration)
    .http_only(true)
}

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
/// **Output**: 200 (success) or 401 (error)
#[post("/login", format = "json", data = "<data>")]
pub async fn login(mut db: Connection<Db>, cookies: &CookieJar<'_>, data: Json<LoginData<'_>>) -> Status {
  let hashed_password: Option<String> = sqlx
    ::query("SELECT password FROM users WHERE email = ?")
    .bind(data.email)
    .fetch_one(&mut **db).await
    .and_then(|row: sqlx::sqlite::SqliteRow| Ok(row.try_get::<String, _>(0)?))
    .ok();

  if let Some(hash) = &hashed_password {
    if !verify(data.password, hash).unwrap() {
      return Status::Unauthorized;
    }
  } else {
    return Status::Unauthorized;
  }

  cookies.add_private(create_cookie("auth_token", hashed_password.unwrap()));
  Status::Ok
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
pub async fn signup(mut db: Connection<Db>, cookies: &CookieJar<'_>, data: Json<LoginData<'_>>) -> Status {
  let password_strength: zxcvbn::Entropy = zxcvbn(data.password, &[data.email]);
  if password_strength.score() < zxcvbn::Score::Three {
    return Status::BadRequest;
  }

  let email_in_db: Option<sqlx::sqlite::SqliteRow> = sqlx::query("SELECT * FROM users WHERE email = ?").bind(data.email).fetch_one(&mut **db).await.ok();
  if let Some(_) = email_in_db {
    return Status::Unauthorized;
  }

  let hashed_password: String = hash(data.password, DEFAULT_COST).unwrap();

  let result: Result<sqlx::sqlite::SqliteQueryResult, sqlx::Error> = sqlx
    ::query("INSERT INTO users (password, last_login, email, date_joined) VALUES (?, ?, ?, ?)")
    .bind(&hashed_password)
    .bind(get_unix_seconds() as u32)
    .bind(data.email)
    .bind(get_unix_seconds() as u32)
    .execute(&mut **db).await;

  match result {
    Ok(_) => {
      cookies.add_private(create_cookie("auth_token", hashed_password));
      Status::Ok
    }
    Err(_) => Status::InternalServerError,
  }
}

/// # Logout
/// **Route**: /auth/logout
///
/// **Request method**: GET
///
/// **Input**: N/A
///
/// **Output**: 200 (success) or 400 (error)
#[get("/logout")]
pub fn logout(cookies: &CookieJar<'_>) -> Status {
  let token_cookie: Option<Cookie<'static>> = cookies.get_private("auth_token");

  match token_cookie {
    Some(token) => {
      cookies.remove_private(token);
      Status::Ok
    }
    None => Status::BadRequest,
  }
}
