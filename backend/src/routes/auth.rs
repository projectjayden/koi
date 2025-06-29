use rocket::{ http::{ private::cookie::Expiration, Cookie, CookieJar, SameSite, Status }, time::OffsetDateTime, serde::{ Deserialize, json::Json } };
use crate::{ guards::auth::AuthenticatedUser, models::user::{SerializedUser}, utils::{ db::Db, functions::get_unix_seconds } };
use bcrypt::{ DEFAULT_COST, hash, verify };
use rocket_db_pools::sqlx::{ self, Row };
use rocket_db_pools::Connection;
use zxcvbn::zxcvbn;
use uuid::Uuid;

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

/// # Init
/// **Route**: /auth/init
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// ```ts
/// {
///   uuid: string;
///   email: string;
///   last_login: number;
///   date_joined: number;
///   store_id: number | null;
///   is_subscribed: boolean;
///   deal_alert_active: boolean;
///   deal_alert_radius: number;
///   preferences: string;
/// }
/// ```
#[get("/init", format = "json")]
pub async fn init(user: AuthenticatedUser) -> Json<SerializedUser> {
  Json(user.0.serialize())
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
    ::query("SELECT uuid, password FROM users WHERE email = ?")
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

/// # Logout
/// **Route**: /auth/logout
///
/// **Request method**: GET
///
/// **Input**: N/A
///
/// **Output**:
/// - 200 (success)
/// - 400 (error)
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
