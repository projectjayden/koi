use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct ManageSubscriptionData {
  /// Whether the user should now be subscribed or unsubscribed.
  ///
  /// If the user has just unsubscribed, this should be `false`.
  new_status: bool,
}

/// # Manage Subscription
/// **Route**: /user/account/subscription
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   new_status: boolean;
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
#[get("/subscription", format = "json", data = "<data>")]
pub async fn subscription(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<ManageSubscriptionData>) -> Status {
  // TODO: subscription
  sqlx
    ::query("UPDATE users SET is_subscribed = ? WHERE uuid = ?")
    .bind(data.0.new_status as u8)
    .bind(&user.0.uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
