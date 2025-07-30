use crate::utils::{ db::Db, functions::get_unix_seconds, jwt::generate_jwt };
use rocket::{ http::Status, serde::{ Serialize, Deserialize, json::Json } };
use bcrypt::{ DEFAULT_COST, hash };
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use zxcvbn::zxcvbn;
use uuid::Uuid;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct SignupData<'r> {
  email: &'r str,
  password: &'r str,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SignupReturn {
  token: String,
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
/// ```ts
/// {
///   token: string;
/// }
/// ```
/// - 400 (password too weak)
/// - 401 (email already used)
/// - 500 (error)
#[post("/signup", format = "json", data = "<data>")]
pub async fn signup(mut db: Connection<Db>, data: Json<SignupData<'_>>) -> Result<Json<SignupReturn>, Status> {
  let password_strength: zxcvbn::Entropy = zxcvbn(data.password, &[data.email]);
  if password_strength.score() < zxcvbn::Score::Three {
    return Err(Status::BadRequest);
  }

  let email_in_db: Option<sqlx::sqlite::SqliteRow> = sqlx::query("SELECT * FROM users WHERE email = $1").bind(data.email).fetch_one(&mut **db).await.ok();
  if let Some(_) = email_in_db {
    return Err(Status::Unauthorized);
  }

  let hashed_password: String = hash(data.password, DEFAULT_COST).unwrap();

  let uuid: String = Uuid::new_v4().to_string();
  sqlx
    ::query("INSERT INTO users (uuid, password, last_login, email, date_joined) VALUES ($1, $2, $3, $4, $5)")
    .bind(Uuid::new_v4().to_string())
    .bind(&hashed_password)
    .bind(get_unix_seconds() as u32)
    .bind(data.email)
    .bind(get_unix_seconds() as u32)
    .execute(&mut **db).await
    .unwrap();

  Ok(
    Json(SignupReturn {
      token: generate_jwt(&uuid).unwrap(),
    })
  )
}
