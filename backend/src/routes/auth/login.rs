use crate::utils::{ db::Db, functions::get_unix_seconds, jwt::generate_jwt };
use crate::models::{ stores::Store, users::{ SerializedUser, User } };
use rocket::{ http::Status, serde::{ Deserialize, json::Json } };
use rocket_db_pools::sqlx::{ self, Row };
use rocket_db_pools::Connection;
use super::init::InitOutput;
use bcrypt::verify;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct LoginData {
  email: String,
  password: String,
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
/// **Output**: Same as /auth/init
#[post("/login", data = "<data>")]
pub async fn login(mut db: Connection<Db>, data: Json<LoginData>) -> Result<Json<(String, InitOutput)>, Status> {
  let user_data: Option<(String, String, Option<String>)> = sqlx
    ::query("SELECT uuid, password, store_uuid FROM users WHERE email = $1")
    .bind(&data.email)
    .fetch_one(&mut **db).await
    .and_then(|row: sqlx::sqlite::SqliteRow| {
      let uuid: String = row.try_get::<String, _>("uuid").unwrap();
      let password: String = row.try_get::<String, _>("password").unwrap();
      let store_uuid: Option<String> = row.try_get::<Option<String>, _>("store_uuid").unwrap();
      Ok((uuid, password, store_uuid))
    })
    .ok();

  match &user_data {
    Some((_, hashed_password, _)) => {
      if !verify(&data.password, hashed_password.as_str()).unwrap() {
        return Err(Status::Unauthorized);
      }
    }
    None => {
      return Err(Status::Unauthorized);
    }
  }

  let (uuid, _, store_uuid) = user_data.unwrap();

  sqlx
    ::query("UPDATE users SET last_login = $1 WHERE uuid = $2")
    .bind(get_unix_seconds() as u32)
    .bind(&uuid)
    .execute(&mut **db).await
    .unwrap();

  let serialized_user: SerializedUser = User::new(&mut **db, uuid.clone()).await.unwrap().serialize(&mut db).await;
  if serialized_user.store_uuid.is_none() {
    return Ok(Json((generate_jwt(&uuid).unwrap(), InitOutput::User(serialized_user))));
  }

  let store: Store = Store::new(&mut db, store_uuid.unwrap()).await.unwrap();
  Ok(Json((generate_jwt(&uuid).unwrap(), InitOutput::Store((serialized_user, store)))))
}
