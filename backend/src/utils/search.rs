use rocket_db_pools::sqlx::{ self, sqlite::SqliteRow, Row, SqliteConnection };
use crate::{ models::stores::Item, utils::functions::get_unix_seconds };
use rocket::serde::Deserialize;
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

/// Items are sorted by:
///
/// 1. Prioritization described in `query`
/// 2. Cheapest price (within `distance_filter` miles of the user's location)
/// 3. Distance from the user's location
pub async fn item_search(
  db: &mut SqliteConnection,
  query: &str,
  price_filter: PriceFilter,
  distance_filter: DistanceFilter,
  limit: u32,
  offset: u32,
  latitude: f32,
  longitude: f32
) -> (usize, Vec<Item>) {
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
    .bind(&query)
    .fetch_one(&mut *db).await
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
    .bind(&query)
    .bind(limit)
    .bind(offset)
    .fetch_all(&mut *db).await
    .and_then(|rows: Vec<SqliteRow>| {
      Ok(
        rows
          .into_iter()
          .map(|row: SqliteRow| {
            let uuid: String = row.try_get::<String, _>("uuid").unwrap();
            let name: String = row.try_get::<String, _>("name").unwrap();
            let price: f32 = row.try_get::<f32, _>("price").unwrap();
            let manufacturer: Option<String> = row.try_get::<Option<String>, _>("manufacturer").unwrap();
            let in_stock: bool = row.try_get::<bool, _>("in_stock").unwrap();
            let store_uuid: String = row.try_get::<String, _>("store_uuid").unwrap();
            let deal_uuid: Option<String> = row.try_get::<Option<String>, _>("deal_uuid").unwrap();
            let image: Option<String> = row.try_get::<Option<String>, _>("image").unwrap();
            Item::new(uuid, name, price, manufacturer, in_stock, store_uuid, deal_uuid, image)
          })
          .collect()
      )
    })
    .unwrap();

  (total_items as usize, items)
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
