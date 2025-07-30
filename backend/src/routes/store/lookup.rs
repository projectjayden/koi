use crate::models::stores::{ Store, Item, Deal, SerializedStore, SerializedStoreReview, StoreReview };
use crate::{ guards::auth::AuthenticatedUser, utils::db::Db };
use rocket::{ http::Status, serde::json::Json };
use rocket::serde::{ Deserialize, Serialize };
use rocket_db_pools::Connection;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct LookupInput {
  /// GPS coordinate of the store.
  ///
  /// Format: `<latitude>, <longitude>`
  geolocation: String,
  /// Whether to include store info in the response.
  get_store_info: bool,
  /// Whether to include inventory in the response.
  get_items: bool,
  /// Whether to include deals in the response.
  get_deals: bool,
  /// Whether to include reviews in the response.
  get_reviews: bool,
  /// Number of reviews to retreive.
  ///
  /// Defaults to `10`.
  ///
  /// If `get_reviews` is `false`, this field can be ommitted.
  review_limit: Option<u32>,
  /// Offset used when retreiving reviews.
  ///
  /// Defaults to `0`.
  ///
  /// If `get_reviews` is `false`, this field can be ommitted.
  review_offset: Option<u32>,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct LookupOutput {
  pub store: Option<SerializedStore>,
  pub items: Option<Vec<Item>>,
  pub deals: Option<Vec<Deal>>,
  pub reviews: Option<Vec<SerializedStoreReview>>,
  /// Total number of reviews.
  ///
  /// Used for pagination.
  pub total_reviews: Option<usize>,
}

/// # Store Lookup
/// **Route**: /store/lookup
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///  geolocation: `${number}, ${number}`;
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
/// ```ts
/// {
///   store?: {
///     uuid: string;
///     name: string;
///     latitude: number;
///     longitude: number;
///     phone: string | null;
///     email: string | null;
///     open_hours: [[string, string], [string, string], ...x5] | null;
///   },
///   items?: {
///     uuid: string;
///     name: string;
///     price: number;
///     manufacturer: string | null;
///     in_stock: boolean;
///     store_uuid: string;
///     deal_uuid: string | null;
///     image: string | null;
///   }[],
///   deals?: {
///     uuid: string;
///     store_uuid: string;
///     name: string;
///     description: string | null;
///     start_date: number;
///     end_date: number;
///     type: number;
///     value_1: number;
///     value_2: number | null;
///   }[],
///   reviews?: {
///     user_uuid: string;
///     store_uuid: string;
///     rating: number;
///     description: string;
///   }[],
///   total_reviews?: number;
/// }
/// ```
#[post("/lookup", format = "json", data = "<data>")]
pub async fn lookup(mut db: Connection<Db>, _user: AuthenticatedUser, data: Json<LookupInput>) -> Result<Json<LookupOutput>, Status> {
  // * if get_reviews is true but review_limit or review_offset is missing
  if data.0.get_reviews && (data.0.review_limit.is_none() || data.0.review_offset.is_none()) {
    return Err(Status::BadRequest);
  }

  let (latitude, longitude) = match data.0.geolocation.split(", ").collect::<Vec<&str>>().as_slice() {
    [lat, long] => (*lat, *long),
    _ => {
      return Err(Status::InternalServerError);
    }
  };

  println!("latitude: {}, longitude: {}", latitude, longitude);
  let store: Option<Store> = Store::from_geolocation(&mut **db, latitude, longitude).await;
  if let None = store {
    return Err(Status::NotFound);
  }
  let store: Store = store.unwrap();

  let items: Option<Vec<Item>> = if data.0.get_items { Some((&store).get_items(&mut **db).await) } else { None };

  let deals: Option<Vec<Deal>> = if data.0.get_deals { Some((&store).get_deals(&mut **db).await) } else { None };

  let review_data: Option<(usize, Vec<StoreReview>)> = if data.0.get_reviews { Some((&store).get_reviews(&mut **db, data.0.review_limit.unwrap(), data.0.review_offset.unwrap()).await) } else { None };
  let (total_reviews, reviews) = match review_data {
    Some((size, reviews)) => {
      let mut serialized_reviews: Vec<SerializedStoreReview> = vec![];
      for review in reviews {
        serialized_reviews.push(review.serialize().await);
      }
      (Some(size), Some(serialized_reviews))
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
