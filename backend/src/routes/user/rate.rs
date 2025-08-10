use crate::{ guards::auth::AuthenticatedUser, utils::functions::get_unix_seconds };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct RateInput {
  /// UUID of the store being rated.
  store_uuid: String,
  /// Rating from `0.0` to `5.0`.
  rating: f32,
  /// Optional description of the rating.
  description: Option<String>,
}

/// # Rate Store
/// **Route**: /user/rate
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   storeUuid: string;
///   rating: number;
///   description?: string;
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
/// - 400 (invalid rating number)
#[post("/rate", data = "<data>")]
pub async fn rate(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<RateInput>) -> Status {
  if data.0.rating < 0.0 || data.0.rating > 5.0 {
    return Status::BadRequest;
  }

  let rating: f32 = data.0.rating * 10.0;
  let rating: f32 = rating.trunc() / 10.0; // * make sure it only has 1 decimal place

  sqlx
    ::query("INSERT INTO store_reviews (user_uuid, store_uuid, rating, description, created_at) VALUES ($1, $2, $3, $4, $5)")
    .bind(user.0.uuid)
    .bind(data.0.store_uuid)
    .bind(rating.to_string())
    .bind(data.0.description)
    .bind(get_unix_seconds() as u32)
    .execute(&mut **db).await
    .unwrap();

  Status::Ok
}
