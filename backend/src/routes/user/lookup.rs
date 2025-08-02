use crate::{ guards::auth::AuthenticatedUser, models::users::User, utils::db::Db };
use crate::models::stores::{ SerializedStoreReview, StoreReview };
use rocket::{ http::Status, serde::json::Json };
use rocket::serde::{ Deserialize, Serialize };
use crate::models::users::SerializedUser;
use rocket_db_pools::Connection;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct LookupInput {
  /// Whether to include user info in the response.
  pub get_user_info: bool,
  /// Whether to include allergies in the response.
  pub get_allergies: bool,
  /// Whether to include reviews in the response.
  pub get_reviews: bool,
  /// Number of reviews to retreive.
  ///
  /// Defaults to `10`.
  ///
  /// If `get_reviews` is `false`, this field can be ommitted.
  pub review_limit: Option<u32>,
  /// Offset used when retreiving reviews.
  ///
  /// Defaults to `0`.
  ///
  /// If `get_reviews` is `false`, this field can be ommitted.
  pub review_offset: Option<u32>,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct LookupOutput {
  pub user: Option<SerializedUser>,
  pub allergies: Option<Vec<(u32, String)>>,
  pub reviews: Option<Vec<SerializedStoreReview>>,
  /// Total number of reviews.
  ///
  /// Used for pagination.
  pub total_reviews: Option<usize>,
}

/// # User Lookup
/// **Route**: /user/lookup/<uuid>
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///  get_user_info: boolean;
///  get_allergies: boolean;
///  get_reviews: false;
/// } | {
///  get_user_info: boolean;
///  get_allergies: boolean;
///  get_reviews: true;
///  review_limit: number;
///  review_offset: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// {
///   user?: {
///     uuid: string;
///     email: string;
///     last_login: number;
///     date_joined: number;
///     store_id: number | null;
///     is_subscribed: boolean;
///     deal_alert_active: boolean;
///     deal_alert_radius: number;
///     preferences: string;
///   },
///   allergies?: [number, string][]; // [id, name][]
///   reviews?: {
///     user_uuid: string;
///     store_uuid: string;
///     rating: number;
///     description: string;
///   }[],
///   total_reviews?: number;
/// }
/// ```
#[post("/lookup/<uuid>", format = "json", data = "<data>")]
pub async fn lookup(mut db: Connection<Db>, _user: AuthenticatedUser, uuid: &str, data: Json<LookupInput>) -> Result<Json<LookupOutput>, Status> {
  // * if get_reviews is true but review_limit or review_offset is missing
  if data.0.get_reviews && (data.0.review_limit.is_none() || data.0.review_offset.is_none()) {
    return Err(Status::BadRequest);
  }

  let user: Option<User> = User::new(&mut **db, uuid.to_string()).await;
  if let None = user {
    return Err(Status::NotFound);
  }
  let user: User = user.unwrap();

  let allergies: Option<Vec<(u32, String)>> = if data.0.get_allergies { Some((&user).get_allergies(&mut **db).await) } else { None };

  let review_data: Option<(usize, Vec<StoreReview>)> = if data.0.get_reviews { Some((&user).get_reviews(&mut **db, data.0.review_limit.unwrap(), data.0.review_offset.unwrap()).await) } else { None };
  let (total_reviews, reviews) = match review_data {
    Some((size, reviews)) => {
      (
        Some(size),
        Some(
          reviews
            .into_iter()
            .map(|review: StoreReview| review.serialize())
            .collect()
        ),
      )
    }
    None => {
      if data.0.get_reviews {
        return Err(Status::BadRequest);
      }
      (None, None)
    }
  };

  let user: Option<SerializedUser> = if data.0.get_user_info { Some(user.serialize()) } else { None };

  Ok(
    Json(LookupOutput {
      user,
      allergies,
      reviews,
      total_reviews,
    })
  )
}
