pub mod lookup;
pub mod create;

pub use lookup::lookup as Lookup;
pub use create::create as Create;

use crate::models::stores::{ Store, SerializedItem, SerializedDeal, SerializedStore, StoreReview };
use crate::guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use crate::utils::db::Db;
use lookup::LookupOutput;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct StoreInfoInput {
  /// Whether to include store info in the response.
  pub get_store_info: bool,
  /// Whether to include inventory in the response.
  pub get_items: bool,
  /// Whether to include deals in the response.
  pub get_deals: bool,
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

/// # Store Informaton
/// Same as /store/lookup, but gets the current store's information
///
/// **Route**: /store
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///  get_store_info: boolean;
///  get_items: boolean;
///  get_deals: boolean;
///  get_reviews: false;
/// } | {
///  get_store_info: boolean;
///  get_items: boolean;
///  get_deals: boolean;
///  get_reviews: true;
///  review_limit: number;
///  review_offset: number;
/// }
/// ```
///
/// **Output**:
///
/// Same as /store/lookup
#[post("/", format = "json", data = "<data>")]
pub async fn store_info(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, data: Json<StoreInfoInput>) -> Result<Json<LookupOutput>, Status> {
  // * if get_reviews is true but review_limit or review_offset is missing
  if data.0.get_reviews && (data.0.review_limit.is_none() || data.0.review_offset.is_none()) {
    return Err(Status::BadRequest);
  }

  let store: Option<Store> = Store::new(&mut **db, store.0.uuid).await;
  if let None = store {
    return Err(Status::NotFound);
  }
  let store: Store = store.unwrap();

  let items: Option<Vec<SerializedItem>> = if data.0.get_items {
    Some(
      (&store)
        .get_items(&mut **db).await
        .into_iter()
        .map(|item| item.serialize())
        .collect()
    )
  } else {
    None
  };

  let deals: Option<Vec<SerializedDeal>> = if data.0.get_deals {
    Some(
      (&store)
        .get_deals(&mut **db).await
        .into_iter()
        .map(|deal| deal.serialize())
        .collect()
    )
  } else {
    None
  };

  let review_data: Option<(usize, Vec<StoreReview>)> = if data.0.get_reviews { Some((&store).get_reviews(&mut **db, data.0.review_limit.unwrap(), data.0.review_offset.unwrap()).await) } else { None };
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

  let store: Option<SerializedStore> = if data.0.get_store_info { Some(store.serialize()) } else { None };

  Ok(
    Json(LookupOutput {
      store,
      items,
      deals,
      reviews,
      total_reviews,
    })
  )
}
