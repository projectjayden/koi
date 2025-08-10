use crate::{ models::users::User, utils::{ db::Db, jwt::get_public_key } };
use rocket::{ http::Status, request::{ FromRequest, Outcome }, Request };
use jwt_simple::prelude::*;
use rocket_db_pools::sqlx;

/// **Output**:
/// - `AuthenticatedUser` (success)
/// - 401 (no authorization header, token is invalid, or user not found)
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

      let user_data: Option<User> = User::new(&mut db, uuid).await;

      match user_data {
        Some(user) => {
          return Outcome::Success(AuthenticatedUser(user));
        }
        None => {
          return Outcome::Error((Status::Unauthorized, ()));
        }
      }
    }

    Outcome::Error((Status::Unauthorized, ()))
  }
}
