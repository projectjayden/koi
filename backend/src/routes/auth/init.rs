use crate::{ guards::auth::AuthenticatedUser, models::user::SerializedUser };
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
/// {
///   uuid: string;
///   email: string;
///   last_login: number;
///   date_joined: number;
///   store_id: number | null;
///   is_subscribed: boolean;
///   deal_alert_active: boolean;
///   deal_alert_radius: number;
///   preferences: string;
/// }
/// ```
#[get("/init", format = "json")]
pub async fn init(user: AuthenticatedUser) -> Json<SerializedUser> {
  Json(user.0.serialize())
}
