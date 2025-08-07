use crate::{ guards::auth::AuthenticatedUser, models::stores::{ Item, SerializedItem }, utils::functions::get_unix_seconds };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use crate::utils::db::Db;
use std::f32::consts::PI;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub enum PriceFilter {
  Under5,
  Under10,
  Under20,
  Under50,
  Under100,
  Under200,
  All,
}

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub enum DistanceFilter {
  Under1,
  Under2,
  Under5,
  Under10,
  Under25,
  Under50,
  Under100,
  All,
}

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
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
///   distance_filter?: DistanceFilter;
///   price_filter?: PriceFilter;
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

  let price_query: String = (
    match price_filter {
      PriceFilter::Under5 => "5",
      PriceFilter::Under10 => "10",
      PriceFilter::Under20 => "20",
      PriceFilter::Under50 => "50",
      PriceFilter::Under100 => "100",
      PriceFilter::Under200 => "200",
      PriceFilter::All => "",
    }
  ).to_string();
  let price_query: String = match price_filter {
    PriceFilter::All => "".to_string(),
    _ => format!(" AND effective_price <= {}", price_query),
  };

  let distance_query: u8 = match distance_filter {
    DistanceFilter::Under1 => 1,
    DistanceFilter::Under2 => 2,
    DistanceFilter::Under5 => 5,
    DistanceFilter::Under10 => 10,
    DistanceFilter::Under25 => 25,
    DistanceFilter::Under50 => 50,
    DistanceFilter::Under100 => 100,
    DistanceFilter::All => 0,
  };
  let (min_latitude, max_latitude, min_longitude, max_longitude) = get_bounding_box(latitude, longitude, distance_query as f32);
  let distance_query: String = match distance_filter {
    DistanceFilter::All => "".to_string(),
    _ => format!(" AND store.latitude BETWEEN {} AND {} AND store.longitude BETWEEN {} and {}", min_latitude, max_latitude, min_longitude, max_longitude),
  };

  let match_index: &'static str = "INSTR(LOWER(item.name), LOWER($1))";
  let effective_price: String = format!(
    "COALESCE(
      CASE
        WHEN deal.type = 0 AND deal.end_date >= {} THEN item.price * (1 - deal.value_1 / 100.0)
        ELSE item.price
      END,
      item.price
    )",
    get_unix_seconds()
  );
  let radians_multiplier: f32 = PI / 180.0;
  let longitude: String = format!("((store.longitude * ({}) - {}) * {})", radians_multiplier, longitude.to_radians(), longitude.to_radians().cos());
  let latitude: String = format!("(store.latitude * ({}) - {})", radians_multiplier, latitude.to_radians());
  let distance: String = format!("((3958.8 * 3958.8) * ({} * {} + ({} * {})))", longitude, longitude, latitude, latitude);

  let (total_items,): (u32,) = sqlx
    ::query_as(
      &format!(
        "SELECT
          COUNT(*),
          {} AS match_index,
          {} AS effective_price
        FROM items item
        JOIN stores store ON item.store_uuid = store.uuid
        LEFT JOIN deals deal ON item.deal_uuid = deal.uuid
        
        WHERE match_index > 0{}{}",
        match_index,
        effective_price,
        price_query,
        distance_query
      )
    )
    .bind(&data.0.query)
    .fetch_one(&mut **db).await
    .unwrap();

  let items: Vec<Item> = sqlx
    ::query(
      &format!(
        "SELECT
          item.*,
          store.latitude, store.longitude,
          deal.type AS deal_type, deal.value_1 AS discount_percent, deal.end_date,
          {} AS match_index,
          {} AS effective_price,
          {} AS distance
        FROM items item
        JOIN stores store ON item.store_uuid = store.uuid
        LEFT JOIN deals deal ON item.deal_uuid = deal.uuid
        
        WHERE match_index > 0{}{}

        ORDER BY match_index ASC, effective_price ASC, distance ASC

        LIMIT $2 OFFSET $3",
        match_index,
        effective_price,
        distance,
        price_query,
        distance_query
      )
    )
    .bind(data.0.query)
    .bind(limit)
    .bind(offset)
    .fetch_all(&mut **db).await
    .and_then(|rows: Vec<SqliteRow>| {
      Ok(
        rows
          .into_iter()
          .map(|row: SqliteRow| {
            let id: u32 = row.try_get::<u32, _>("id").unwrap();
            let uuid: String = row.try_get::<String, _>("uuid").unwrap();
            let name: String = row.try_get::<String, _>("name").unwrap();
            let price: f32 = row.try_get::<f32, _>("price").unwrap();
            let manufacturer: Option<String> = row.try_get::<Option<String>, _>("manufacturer").unwrap();
            let in_stock: bool = row.try_get::<bool, _>("in_stock").unwrap();
            let store_uuid: String = row.try_get::<String, _>("store_uuid").unwrap();
            let deal_uuid: Option<String> = row.try_get::<Option<String>, _>("deal_uuid").unwrap();
            let image: Option<String> = row.try_get::<Option<String>, _>("image").unwrap();
            Item::new(id, uuid, name, price, manufacturer, in_stock, store_uuid, deal_uuid, image)
          })
          .collect()
      )
    })
    .unwrap();

  let mut serialized_items: Vec<SerializedItem> = vec![];
  for item in items {
    serialized_items.push(item.serialize(&mut *db).await);
  }

  Ok(Json((total_items as usize, serialized_items)))
}

/// Returns (min_latitude, max_latitude, min_longitude, max_longitude)
fn get_bounding_box(center_latitude: f32, center_longitude: f32, distance: f32) -> (f32, f32, f32, f32) {
  if distance == 0.0 {
    return (0.0, 0.0, 0.0, 0.0);
  }

  // * 1 degree of latitude = 69 miles
  let latitude_offset: f32 = distance / 69.0; // nice
  let longitude_offset: f32 = distance / (69.0 * center_latitude.to_radians().cos());

  (center_latitude - latitude_offset, center_latitude + latitude_offset, center_longitude - longitude_offset, center_longitude + longitude_offset)
}
