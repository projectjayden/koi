use crate::{ guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore }, models::users::Review };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct ReviewInput {
  /// Number of reviews to get.
  ///
  /// Defaults to `20`.
  pub limit: Option<u32>,
  /// Offset of reviews.
  ///
  /// Defaults to `0`.
  pub offset: Option<u32>,
}

/// # Get Reviews
/// **Route**: /store/get-reviews
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   limit?: number;
///   offset?: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// [
///   number; // total reviews
///   {
///     userUuid: string;
///     storeUuid: string;
///     rating: number;
///     description: string | null;
///   }[];
/// ]
/// ```
#[post("/get-reviews", data = "<data>")]
pub async fn get_reviews(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, data: Json<ReviewInput>) -> Result<Json<(usize, Vec<Review>)>, Status> {
  let limit: u32 = data.0.limit.unwrap_or(20);
  let offset: u32 = data.0.offset.unwrap_or(0);

  let (total_reviews, reviews) = store.0.get_reviews(&mut db, limit, offset).await;
  Ok(Json((total_reviews, reviews)))
}
