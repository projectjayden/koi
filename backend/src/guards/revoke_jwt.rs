use rocket::{ request::{ FromRequest, Outcome }, Request };
use crate::utils::{ db::Db, jwt::get_public_key };
use jwt_simple::prelude::*;
use rocket_db_pools::sqlx;

/// Should **ALWAYS** be called after `AuthenticatedUser`.
pub struct RevokeJWT();

#[rocket::async_trait]
impl<'r> FromRequest<'r> for RevokeJWT {
  type Error = ();

  async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
    let token: &str = request.headers().get_one("Authorization").unwrap();
    let token: String = if token.starts_with("Bearer ") { token.trim_start_matches("Bearer ").to_string() } else { token.to_string() };

    let claims: JWTClaims<NoCustomClaims> = get_public_key().unwrap().verify_token::<NoCustomClaims>(&token, None).ok().unwrap();
    let mut db: sqlx::pool::PoolConnection<sqlx::Sqlite> = request.rocket().state::<Db>().unwrap().acquire().await.unwrap();
    sqlx
      ::query("INSERT INTO revoked_tokens (uuid, expiration) VALUES ($1, $2)")
      .bind(&claims.jwt_id)
      .bind(claims.expires_at.unwrap().as_secs() as u32)
      .execute(&mut *db).await
      .ok()
      .unwrap();

    Outcome::Success(RevokeJWT())
  }
}
