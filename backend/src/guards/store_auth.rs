use crate::{ models::{ stores::Store, users::User }, utils::{ db::Db, jwt::get_public_key } };
use rocket::{ http::Status, request::{ FromRequest, Outcome }, Request };
use jwt_simple::prelude::*;
use rocket_db_pools::sqlx;

/// **Output**:
/// - `AuthenticatedStore` (success)
/// - 400 (store not found)
/// - 403 (no store associated with user)
pub struct AuthenticatedStore(pub Store);

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedStore {
  type Error = ();

  async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
    let token: &str = request.headers().get_one("Authorization").unwrap();
    let token: String = if token.starts_with("Bearer ") { token.trim_start_matches("Bearer ").to_string() } else { token.to_string() };

    let claims: JWTClaims<NoCustomClaims> = get_public_key().unwrap().verify_token::<NoCustomClaims>(&token, None).ok().unwrap();
    let mut db: sqlx::pool::PoolConnection<sqlx::Sqlite> = request.rocket().state::<Db>().unwrap().acquire().await.unwrap();

    let uuid: String = claims.subject.unwrap();
    let user_data: User = User::new(&mut db, uuid).await.unwrap();
    if user_data.store_uuid.is_none() {
      return Outcome::Error((Status::Forbidden, ()));
    }

    let store_data: Option<Store> = Store::new(&mut db, user_data.store_uuid.unwrap()).await;

    match store_data {
      Some(store) => {
        return Outcome::Success(AuthenticatedStore(store));
      }
      None => {
        return Outcome::Error((Status::BadRequest, ()));
      }
    }
  }
}
