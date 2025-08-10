use crate::models::stores::{ Store, Item, SerializedItem, Deal };
use crate::{ guards::auth::AuthenticatedUser, utils::db::Db };
use rocket::{ http::Status, serde::json::Json };
use rocket::serde::{ Deserialize, Serialize };
use crate::models::users::Review;
use rocket_db_pools::Connection;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
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
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct LookupOutput {
  pub store: Option<Store>,
  pub items: Option<Vec<SerializedItem>>,
  pub deals: Option<Vec<Deal>>,
  pub reviews: Option<Vec<Review>>,
  /// Total number of reviews.
  ///
  /// Used for pagination.
  pub total_reviews: Option<usize>,
}

/// # Store Lookup
/// **DO NOT** use this to look up the store's own information.
///
/// **Route**: /store/lookup
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///  geolocation: `${number}, ${number}`;
///  getStoreInfo: boolean;
///  getItems: boolean;
///  getDeals: boolean;
///  getReviews: false;
/// } | {
///  getStoreInfo: boolean;
///  getItems: boolean;
///  getDeals: boolean;
///  getReviews: true;
///  reviewLimit: number;
///  reviewOffset: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// {
///   store?: {
///     uuid: string;
///     name: string;
///     description: string | null;
///     latitude: number;
///     longitude: number;
///     phone: string | null;
///     email: string | null;
///     openHours: [[string, string], [string, string], ...x5] | null;
///   },
///   items?: {
///     uuid: string;
///     name: string;
///     price: number;
///     manufacturer: string | null;
///     inStock: boolean;
///     storeUuid: string;
///     deal: {
///       uuid: string;
///       storeUuid: string;
///       name: string;
///       description: string | null;
///       startDate: number;
///       endDate: number;
///       type: number;
///       value1: number;
///       value2: number | null;
///     } | null;
///     image: string | null;
///   }[],
///   deals?: {
///     uuid: string;
///     storeUuid: string;
///     name: string;
///     description: string | null;
///     startDate: number;
///     endDate: number;
///     type: number;
///     value1: number;
///     value2: number | null;
///   }[],
///   reviews?: {
///     userUuid: string;
///     storeUuid: string;
///     rating: number;
///     description: string;
///   }[],
///   totalReviews?: number;
/// }
/// ```
#[post("/lookup", data = "<data>")]
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

  let store: Option<Store> = Store::from_geolocation(&mut **db, latitude, longitude).await;
  if let None = store {
    return Err(Status::NotFound);
  }
  let store: Store = store.unwrap();

  let items: Option<Vec<SerializedItem>> = if data.0.get_items {
    let unserialized_items: Vec<Item> = (&store).get_items(&mut **db).await;

    let mut serialized_items: Vec<SerializedItem> = vec![];
    for item in unserialized_items {
      serialized_items.push(item.serialize(&mut **db).await);
    }

    Some(serialized_items)
  } else {
    None
  };

  let deals: Option<Vec<Deal>> = if data.0.get_deals { Some((&store).get_deals(&mut **db).await) } else { None };

  let review_data: Option<(usize, Vec<Review>)> = if data.0.get_reviews { Some((&store).get_reviews(&mut **db, data.0.review_limit.unwrap(), data.0.review_offset.unwrap()).await) } else { None };
  let (total_reviews, reviews) = match review_data {
    Some((size, reviews)) => { (Some(size), Some(reviews)) }
    None => {
      if data.0.get_reviews {
        return Err(Status::BadRequest);
      }
      (None, None)
    }
  };

  let store: Option<Store> = if data.0.get_store_info { Some(store) } else { None };

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
