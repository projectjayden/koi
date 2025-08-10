use crate::{ guards::auth::AuthenticatedUser, models::{ stores::Store, users::SerializedUser } };
use crate::utils::{ db::Db, functions::get_unix_seconds, jwt::generate_jwt };
use rocket::serde::{ json::Json, Serialize };
use rocket_db_pools::{ sqlx, Connection };

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub enum InitOutput {
  User(SerializedUser),
  Store((SerializedUser, Store)),
}

/// # Init
/// **Route**: /auth/init
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
///
/// User:
/// ```ts
/// [
///   string, // new token
///   {
///     User: {
///       uuid: string;
///       name: string;
///       bio: string | null;
///       email: string;
///       lastLogin: number;
///       dateJoined: number;
///       storeId: number | null;
///       isSubscribed: boolean;
///       preferences: string[];
///       allergies: string[];
///       followers: number;
///       following: number;
///     }
///   }
/// ]
/// ```
///
/// Store:
/// ```ts
/// [
///   string, // new token
///   {
///     Store: [
///       { /* Same as User */ },
///       {
///         uuid: string;
///         name: string;
///         description: string | null;
///         latitude: number;
///         longitude: number;
///         phone: string | null;
///         email: string | null;
///         openHours: [[string, string], [string, string], ...x5] | null;
///       }
///     ]
///   }
/// ]
/// ```
#[get("/init")]
pub async fn init(mut db: Connection<Db>, user: AuthenticatedUser) -> Json<(String, InitOutput)> {
  sqlx
    ::query("UPDATE users SET last_login = $1 WHERE uuid = $2")
    .bind(get_unix_seconds() as u32)
    .bind(&user.0.uuid)
    .execute(&mut **db).await
    .unwrap();

  let serialized_user: SerializedUser = user.0.serialize(&mut db).await;
  if user.0.store_uuid.is_none() {
    return Json((generate_jwt(&user.0.uuid).unwrap(), InitOutput::User(serialized_user)));
  }

  let store: Store = Store::new(&mut db, user.0.store_uuid.unwrap()).await.unwrap();
  Json((generate_jwt(&user.0.uuid).unwrap(), InitOutput::Store((serialized_user, store))))
}
