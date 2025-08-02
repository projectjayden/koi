use crate::{ guards::auth::AuthenticatedUser, models::users::{ SerializedReview, Review } };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
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
/// **Route**: /user/get-reviews
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
///     uuid: number;
///     user_uuid: number;
///     name: string;
///     ingredients: [name: string, amount: number, unit: string][];
///     category: string | null;
///     image: string | null;
///   }[];
/// ]
/// ```
#[post("/get-reviews", format = "json", data = "<data>")]
pub async fn get_reviews(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<ReviewInput>) -> Result<Json<(usize, Vec<SerializedReview>)>, Status> {
  let limit: u32 = data.0.limit.unwrap_or(20);
  let offset: u32 = data.0.offset.unwrap_or(0);

  let (total_reviews, reviews) = user.0.get_reviews(&mut db, limit, offset).await;
  let reviews: Vec<SerializedReview> = reviews
    .into_iter()
    .map(|review: Review| review.serialize())
    .collect();
  Ok(Json((total_reviews, reviews)))
}
