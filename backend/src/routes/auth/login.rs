use rocket::{ http::Status, serde::{ Serialize, Deserialize, json::Json } };
use crate::utils::{ db::Db, jwt::generate_jwt };
use rocket_db_pools::sqlx::{ self, Row };
use rocket_db_pools::Connection;
use bcrypt::verify;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct LoginData<'r> {
  email: &'r str,
  password: &'r str,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct LoginReturnData {
  /// JWT Token. Should be sent in the Authorization header in every request.
  token: String,
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
/// ```ts
/// {
///   token: string
/// }
/// ```
/// - 401 (error)
#[post("/login", format = "json", data = "<data>")]
pub async fn login(mut db: Connection<Db>, data: Json<LoginData<'_>>) -> Result<Json<LoginReturnData>, Status> {
  let user_data: Option<(String, String)> = sqlx
    ::query("SELECT uuid, password FROM users WHERE email = $1")
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
        return Err(Status::Unauthorized);
      }
    }
    None => {
      return Err(Status::Unauthorized);
    }
  }

  let (uuid, _) = user_data.unwrap();
  Ok(
    Json(LoginReturnData {
      token: generate_jwt(&uuid).unwrap(),
    })
  )
}
