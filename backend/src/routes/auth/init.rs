use crate::{
  guards::{ auth::AuthenticatedUser, revoke_jwt::RevokeJWT },
  models::{ stores::{ SerializedStore, Store }, users::SerializedUser },
  utils::{ db::Db, functions::get_unix_seconds, jwt::generate_jwt },
};
use rocket_db_pools::{ sqlx, Connection };
use rocket::serde::{ json::Json, Serialize };

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub enum InitOutput {
  User(SerializedUser),
  Store((SerializedUser, SerializedStore)),
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
///       email: string;
///       last_login: number;
///       date_joined: number;
///       store_id: number | null;
///       is_subscribed: boolean;
///       deal_alert_active: boolean;
///       deal_alert_radius: number;
///       preferences: string;
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
///         latitude: number;
///         longitude: number;
///         phone: string | null;
///         email: string | null;
///         open_hours: [[string, string], [string, string], ...x5] | null;
///       }
///     ]
///   }
/// ]
/// ```
#[get("/init", format = "json")]
pub async fn init(mut db: Connection<Db>, user: AuthenticatedUser, _revoke_jwt: RevokeJWT) -> Json<(String, InitOutput)> {
  sqlx
    ::query("UPDATE users SET last_login = $1 WHERE uuid = $2")
    .bind(get_unix_seconds() as u32)
    .bind(&user.0.uuid)
    .execute(&mut **db).await
    .unwrap();

  let serialized_user: SerializedUser = user.0.serialize();
  if user.0.store_uuid.is_none() {
    return Json((generate_jwt(&user.0.uuid).unwrap(), InitOutput::User(serialized_user)));
  }

  let store: Store = Store::new(&mut db, user.0.store_uuid.unwrap()).await.unwrap();
  Json((generate_jwt(&user.0.uuid).unwrap(), InitOutput::Store((serialized_user, store.serialize()))))
}
