use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct DealsData {
  /// Whether the user should now have deal alerts active or inactive.
  new_status: bool,
  /// The radius of the deal alerts, in miles.
  ///
  /// Must be between `1` and `200`, inclusive.
  ///
  /// If the user is turning off deal alerts, this can be ommitted.
  new_radius: Option<u8>,
}

/// # Manage Deal Alerts
/// **Route**: /user/account/deals
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   new_status: boolean;
///   new_radius?: number;
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
/// - 400 (invalid radius)
#[post("/deals", format = "json", data = "<data>")]
pub async fn deals(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<DealsData>) -> Status {
  let radius: u8 = data.0.new_radius.unwrap_or(0);
  // if radius out of bounds OR no radius but deals is enabled
  if (radius == 0 && data.0.new_status) || radius > 200 {
    return Status::BadRequest;
  }

  sqlx
    ::query("UPDATE users SET deals_alert_active = $1, deals_alert_radius = $2 WHERE uuid = $3")
    .bind(data.0.new_status as u8)
    .bind(radius)
    .bind(&user.0.uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
