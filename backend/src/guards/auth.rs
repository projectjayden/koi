use rocket::{ http::Status, request::{ FromRequest, Outcome }, Request };
use crate::{ models::user::User, utils::db::Db };
use rocket_db_pools::sqlx::{ self, Row };

pub struct AuthenticatedUser(pub User);

#[rocket::async_trait]
impl<'r> FromRequest<'r> for AuthenticatedUser {
  type Error = ();

  async fn from_request(request: &'r Request<'_>) -> Outcome<Self, Self::Error> {
    let auth_cookie: Option<rocket::http::Cookie<'static>> = request.cookies().get_private("auth_token");

    if let Some(cookie) = auth_cookie {
      let uuid: &str = cookie.value();

      let mut db = request.rocket().state::<Db>().unwrap().acquire().await.unwrap();
      let user_data: Option<User> = sqlx
        ::query("SELECT * FROM users WHERE uuid = ?")
        .bind(&uuid)
        .fetch_one(&mut *db).await
        .and_then(|row: sqlx::sqlite::SqliteRow| {
          let id: u32 = row.try_get::<u32, _>("id").unwrap();
          let uuid: String = row.try_get::<String, _>("uuid").unwrap();
          let email: String = row.try_get::<String, _>("email").unwrap();
          let password: String = row.try_get::<String, _>("password").unwrap();
          let last_login: u32 = row.try_get::<u32, _>("last_login").unwrap();
          let date_joined: u32 = row.try_get::<u32, _>("date_joined").unwrap();
          let store_id: Option<u32> = row.try_get::<Option<u32>, _>("store_id").unwrap();
          let is_subscribed: u8 = row.try_get::<u8, _>("is_subscribed").unwrap();
          let deal_alert_active: u8 = row.try_get::<u8, _>("deal_alert_active").unwrap();
          let deal_alert_radius: u8 = row.try_get::<u8, _>("deal_alert_radius").unwrap();
          let preferences: String = row.try_get::<String, _>("preferences").unwrap();
          Ok(User::new(id, uuid, email, password, last_login, date_joined, store_id, is_subscribed, deal_alert_active, deal_alert_radius, preferences))
        })
        .ok();

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
