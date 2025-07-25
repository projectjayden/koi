use crate::{ models::user::User, utils::{ db::Db, jwt::get_public_key } };
use rocket::{ http::Status, request::{ FromRequest, Outcome }, Request };
use rocket_db_pools::sqlx::{ self, Row };
use jwt_simple::prelude::*;

/// **Output**:
/// - `AuthenticatedUser` (success)
/// - 400 (user not found)
/// - 401 (no authorization header, token is invalid, or token is revoked)
pub struct AuthenticatedUser(pub User);

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedUser {
  type Error = ();

  async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
    let token: String = match request.headers().get_one("Authorization") {
      Some(header) if header.starts_with("Bearer ") => { header.trim_start_matches("Bearer ").to_string() }
      _ => {
        return Outcome::Error((Status::Unauthorized, ()));
      }
    };

    if let Ok(claims) = get_public_key().unwrap().verify_token::<NoCustomClaims>(&token, None) {
      let uuid: String = claims.subject.unwrap();

      let mut db: sqlx::pool::PoolConnection<sqlx::Sqlite> = request.rocket().state::<Db>().unwrap().acquire().await.unwrap();

      let token_is_revoked: bool = sqlx::query("SELECT * FROM revoked_tokens WHERE uuid = $1").bind(&claims.jwt_id).fetch_one(&mut *db).await.is_ok();
      if token_is_revoked {
        return Outcome::Error((Status::Unauthorized, ()));
      }

      let user_data: Option<User> = sqlx
        ::query("SELECT * FROM users WHERE uuid = $1")
        .bind(&uuid)
        .fetch_one(&mut *db).await
        .and_then(|row: sqlx::sqlite::SqliteRow| {
          let id: u32 = row.try_get::<u32, _>("id").unwrap();
          let uuid: String = row.try_get::<String, _>("uuid").unwrap();
          let email: String = row.try_get::<String, _>("email").unwrap();
          let password: String = row.try_get::<String, _>("password").unwrap();
          let last_login: u32 = row.try_get::<u32, _>("last_login").unwrap();
          let date_joined: u32 = row.try_get::<u32, _>("date_joined").unwrap();
          let store_uuid: Option<String> = row.try_get::<Option<String>, _>("store_uuid").unwrap();
          let is_subscribed: u8 = row.try_get::<u8, _>("is_subscribed").unwrap();
          let deal_alert_active: u8 = row.try_get::<u8, _>("deal_alert_active").unwrap();
          let deal_alert_radius: u8 = row.try_get::<u8, _>("deal_alert_radius").unwrap();
          let preferences: String = row.try_get::<String, _>("preferences").unwrap();
          Ok(User::new(id, uuid, email, password, last_login, date_joined, store_uuid, is_subscribed, deal_alert_active, deal_alert_radius, preferences))
        })
        .ok();

      match user_data {
        Some(user) => {
          return Outcome::Success(AuthenticatedUser(user));
        }
        None => {
          return Outcome::Error((Status::BadRequest, ()));
        }
      }
    }

    Outcome::Error((Status::Unauthorized, ()))
  }
}
