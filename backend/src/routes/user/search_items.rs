use crate::{ guards::auth::AuthenticatedUser, models::stores::SerializedItem };
use crate::utils::search::{ item_search, DistanceFilter, PriceFilter };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct SearchItemInput {
  /// GPS coordinate of the user's current location.
  ///
  /// Format: `<latitude>, <longitude>`
  pub geolocation: String,
  /// Search query.
  ///
  /// Prioritzes items with the query in earlier positions.
  ///
  /// Example: if `"cake"` is the query, `"cake mix"` will be prioritized over `"vanilla cake mix"`.
  pub query: String,
  /// Optional price filter.
  ///
  /// Defaults to `All`.
  ///
  /// Options for `price_filter` are listed in `PriceFilter` (`Under1`, `Under100`, etc).
  pub price_filter: Option<PriceFilter>,
  /// Optional distance filter.
  ///
  /// Defaults to `Under5`.
  ///
  /// Options for `distance_filter` are listed in `DistanceFilter` (`Under1`, `Under100`, etc).
  pub distance_filter: Option<DistanceFilter>,
  /// Optional limit.
  ///
  /// Defaults to `20`.
  pub limit: Option<u32>,
  /// Optional offset.
  ///
  /// Defaults to `0`.
  pub offset: Option<u32>,
}

/// # Search Items
/// Items are sorted by:
///
/// 1. Prioritization described in `SearchItemInput.query`
/// 2. Cheapest price (within `distance_filter` miles of the user's location)
/// 3. Distance from the user's location
///
/// **Route**: /user/search-items
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   geolocation: `${number}, ${number}`;
///   query: string;
///   distanceFilter?: DistanceFilter;
///   priceFilter?: PriceFilter;
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
///     userUuid: number;
///     name: string;
///     ingredients: [name: string, amount: number, unit: string][];
///     category: string | null;
///     image: string | null;
///   }[];
/// ]
/// ```
#[post("/search-items", data = "<data>")]
pub async fn search_items(mut db: Connection<Db>, _user: AuthenticatedUser, data: Json<SearchItemInput>) -> Result<Json<(usize, Vec<SerializedItem>)>, Status> {
  let price_filter: PriceFilter = data.0.price_filter.unwrap_or(PriceFilter::All);
  let distance_filter: DistanceFilter = data.0.distance_filter.unwrap_or(DistanceFilter::Under5);
  let limit: u32 = data.0.limit.unwrap_or(20);
  let offset: u32 = data.0.offset.unwrap_or(0);

  let (latitude, longitude) = match
    data.0.geolocation
      .split(", ")
      .map(|str: &str| str.parse::<f32>().unwrap())
      .collect::<Vec<f32>>()
      .as_slice()
  {
    [lat, long] => (*lat, *long),
    _ => {
      return Err(Status::InternalServerError);
    }
  };

  let (total_items, items) = item_search(&mut **db, &data.0.query, price_filter, distance_filter, limit, offset, latitude, longitude).await;

  let mut serialized_items: Vec<SerializedItem> = vec![];
  for item in items {
    serialized_items.push(item.serialize(&mut *db).await);
  }

  Ok(Json((total_items, serialized_items)))
}
