use crate::{ models::users::{ SerializedUser, User }, utils::{ db::Db, functions::get_unix_seconds, jwt::generate_jwt } };
use rocket::{ http::Status, serde::{ Serialize, Deserialize, json::Json } };
use bcrypt::{ DEFAULT_COST, hash };
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use zxcvbn::zxcvbn;
use uuid::Uuid;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct SignupData {
  email: String,
  password: String,
  name: String,
  bio: Option<String>,
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
///   name: string;
///   bio?: string;
/// }
/// ```
///
/// **Output**:
/// - same as /auth/init (success)
/// - 400 (password too weak)
/// - 401 (email already used)
/// - 500 (error)
#[post("/signup", data = "<data>")]
pub async fn signup(mut db: Connection<Db>, data: Json<SignupData>) -> Result<Json<(String, SerializedUser)>, Status> {
  let password_strength: zxcvbn::Entropy = zxcvbn(&data.0.password, &[&data.0.email]);
  if password_strength.score() < zxcvbn::Score::Three {
    return Err(Status::BadRequest);
  }

  let email_in_db: Option<sqlx::sqlite::SqliteRow> = sqlx::query("SELECT * FROM users WHERE email = $1").bind(&data.0.email).fetch_one(&mut **db).await.ok();
  if let Some(_) = email_in_db {
    return Err(Status::Unauthorized);
  }

  let hashed_password: String = hash(&data.0.password, DEFAULT_COST).unwrap();

  // TODO: change output to init
  let uuid: String = Uuid::new_v4().to_string();
  sqlx
    ::query("INSERT INTO users (uuid, password, name, bio, last_login, email, date_joined) VALUES ($1, $2, $3, $4, $5)")
    .bind(&uuid)
    .bind(hashed_password)
    .bind(data.0.name)
    .bind(data.0.bio)
    .bind(get_unix_seconds() as u32)
    .bind(data.0.email)
    .bind(get_unix_seconds() as u32)
    .execute(&mut **db).await
    .unwrap();

  let token: String = generate_jwt(&uuid).unwrap();
  let user: User = User::new(&mut **db, uuid).await.unwrap();

  Ok(Json((token, user.serialize(&mut **db).await)))
}
