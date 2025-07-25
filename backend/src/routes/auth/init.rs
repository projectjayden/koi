use crate::{ guards::{auth::AuthenticatedUser, revoke_jwt::RevokeJWT}, models::user::SerializedUser, utils::{ db::Db, functions::get_unix_seconds, jwt::generate_jwt } };
use rocket_db_pools::{ sqlx, Connection };
use rocket::serde::json::Json;

/// # Init
/// **Route**: /auth/init
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// ```ts
/// [
///   string, // new token
///   {
///     uuid: string;
///     email: string;
///     last_login: number;
///     date_joined: number;
///     store_id: number | null;
///     is_subscribed: boolean;
///     deal_alert_active: boolean;
///     deal_alert_radius: number;
///     preferences: string;
///   }
/// ]
/// ```
#[get("/init", format = "json")]
pub async fn init(mut db: Connection<Db>, user: AuthenticatedUser, _revoke_jwt: RevokeJWT) -> Json<(String, SerializedUser)> {
  sqlx
    ::query("UPDATE users SET last_login = $1 WHERE uuid = $2")
    .bind(get_unix_seconds() as u32)
    .bind(&user.0.uuid)
    .execute(&mut **db).await
    .unwrap();
  
  Json((generate_jwt(&user.0.uuid).unwrap(), user.0.serialize()))
}
