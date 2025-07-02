use crate::{ guards::auth::AuthenticatedUser, models::user::User, utils::db::Db };
use crate::models::user_review::{ SerializedUserReview, UserReview };
use rocket_db_pools::sqlx::{ self, Row, SqliteConnection, Error };
use rocket::{ http::Status, serde::json::Json };
use rocket::serde::{ Deserialize, Serialize };
use crate::models::user::SerializedUser;
use rocket_db_pools::Connection;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct LookupInput {
  /// Whether to include user info in the response.
  include_user_info: bool,
  /// Whether to include allergies in the response.
  include_allergies: bool,
  /// Whether to include reviews in the response.
  include_reviews: bool,
  /// Number of reviews to retreive.
  ///
  /// Defaults to `10`.
  ///
  /// If `include_reviews` is `false`, this field can be ommitted.
  review_limit: Option<u32>,
  /// Offset used when retreiving reviews.
  ///
  /// Defaults to `0`.
  ///
  /// If `include_reviews` is `false`, this field can be ommitted.
  review_offset: Option<u32>,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct LookupOutput {
  user: Option<SerializedUser>,
  allergies: Option<Vec<String>>,
  reviews: Option<Vec<SerializedUserReview>>,
  /// Total number of reviews.
  ///
  /// Used for pagination.
  total_reviews: Option<usize>,
}

/// # User Lookup
/// **Route**: /user/lookup/<uuid>
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///  include_user_info: boolean;
///  include_allergies: boolean;
///  include_reviews: false;
/// } | {
///  include_user_info: boolean;
///  include_allergies: boolean;
///  include_reviews: true;
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
///   allergies?: string[];
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
pub async fn lookup(mut db: Connection<Db>, _user: AuthenticatedUser, uuid: String, data: Json<LookupInput>) -> Result<Json<LookupOutput>, Status> {
  // if include_reviews is true but review_limit or review_offset is missing
  if data.0.include_reviews && (data.0.review_limit.is_none() || data.0.review_offset.is_none()) {
    return Err(Status::BadRequest);
  }

  let user: Option<User> = get_user_data(&mut **db, &uuid).await;
  if let None = user {
    return Err(Status::NotFound);
  }
  let user: User = user.unwrap();

  let allergies: Option<Vec<String>> = if data.0.include_allergies { get_allergies(&mut **db, user.get_id()).await } else { None };

  let review_data: Option<(usize, Vec<UserReview>)> = if data.0.include_reviews {
    get_reviews(&mut **db, user.get_id(), data.0.review_limit.unwrap(), data.0.review_offset.unwrap()).await
  } else {
    None
  };
  let (total_reviews, reviews) = match review_data {
    Some((size, reviews)) => {
      let mut serialized_reviews: Vec<SerializedUserReview> = vec![];
      for review in reviews {
        serialized_reviews.push(review.serialize(&mut **db).await);
      }
      (Some(size), Some(serialized_reviews))
    }
    None => {
      return Err(Status::BadRequest);
    }
  };

  let user: Option<SerializedUser> = if data.0.include_user_info { Some(user.serialize()) } else { None };

  Ok(
    Json(LookupOutput {
      user,
      allergies,
      reviews,
      total_reviews,
    })
  )
}

async fn get_user_data(db: &mut SqliteConnection, uuid: &String) -> Option<User> {
  sqlx
    ::query("SELECT * FROM users WHERE uuid = ?")
    .bind(uuid)
    .fetch_one(db).await
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
    .ok()
}

async fn get_allergies(db: &mut SqliteConnection, id: u32) -> Option<Vec<String>> {
  sqlx
    ::query("SELECT * FROM user_allergies WHERE user_id = ?")
    .bind(id)
    .fetch_all(db).await
    .and_then(|rows: Vec<sqlx::sqlite::SqliteRow>| {
      let allergies: Vec<String> = rows
        .into_iter()
        .map(|row: sqlx::sqlite::SqliteRow| { row.try_get::<String, _>("allergy").unwrap() })
        .collect();
      return Ok(allergies);
    })
    .ok()
}

/// (total_reviews, reviews)
async fn get_reviews(db: &mut SqliteConnection, id: u32, limit: u32, offset: u32) -> Option<(usize, Vec<UserReview>)> {
  sqlx
    ::query("SELECT * FROM reviews WHERE user_id = ?")
    .bind(id)
    .fetch_all(db).await
    .and_then(|rows: Vec<sqlx::sqlite::SqliteRow>| {
      let num_of_reviews: usize = rows.len();
      if offset + limit > (num_of_reviews as u32) {
        return Err(Error::RowNotFound);
      }

      let mut reviews: Vec<UserReview> = vec![];
      let reviews_to_get: u32 = offset + limit;
      for i in offset..reviews_to_get {
        let row: &sqlx::sqlite::SqliteRow = rows.get(i as usize).unwrap();

        let id: u32 = row.try_get::<u32, _>("id").unwrap();
        let user_id: u32 = row.try_get::<u32, _>("user_id").unwrap();
        let store_id: u32 = row.try_get::<u32, _>("store_id").unwrap();
        let rating: f32 = row.try_get::<f32, _>("rating").unwrap();
        let description: String = row.try_get::<String, _>("description").unwrap();
        reviews.push(UserReview::new(id, user_id, store_id, rating, description));
      }
      return Ok((num_of_reviews, reviews));
    })
    .ok()
}
