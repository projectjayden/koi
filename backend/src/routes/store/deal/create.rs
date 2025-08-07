use crate::guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore };
use rocket::http::Status;
use rocket_db_pools::{ sqlx, Connection };
use rocket::serde::Deserialize;
use rocket::serde::json::Json;
use crate::utils::db::Db;
use uuid::Uuid;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct CreateDealInput {
  /// Name of the deal.
  name: String,
  /// Description of the deal.
  description: Option<String>,
  /// Start date of the deal, as a unix timestamp in seconds.
  start_date: u32,
  /// End date of the deal, as a unix timestamp in seconds.
  end_date: u32,
  /// Type of deal.
  ///
  /// - 0 = `X`% off
  /// - 1 = Buy `X`, get `Y`
  /// - 2 = Buy `X`, get `Y`% off
  /// - 3 = Spend `X`, get `Y`
  /// - 4 = Spend `X`, get `Y`% off
  ///
  /// `X` is the value of `value_1` and `Y` is the value of `value_2`.
  r#type: u8,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  value_1: u8,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  value_2: Option<u8>,
  /// Array of item UUIDs to apply the deal to.
  items: Option<Vec<String>>,
}

/// # Create a Deal
/// **Route**: /store/deal/create
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   name: string;
///   description?: string;
///   start_date: number;
///   end_date: number;
///   type: number;
///   value_1: number;
///   value_2?: number;
///   items?: string[];
/// }
/// ```
///
/// **Output**:
/// - `string` - UUID of the created deal
/// - 400 (type isnt 0 but value_2 is missing)
#[post("/create", data = "<data>")]
pub async fn create(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, data: Json<CreateDealInput>) -> Result<Json<String>, Status> {
  if data.0.r#type != 0 && data.0.value_2.is_none() {
    return Err(Status::BadRequest);
  }

  let value_2: Option<u8> = if data.0.r#type == 0 { None } else { data.0.value_2 };

  let uuid: String = Uuid::new_v4().to_string();

  sqlx
    ::query("INSERT INTO deals (uuid, store_uuid, name, description, start_date, end_date, type, value_1, value_2) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)")
    .bind(&uuid)
    .bind(&store.0.uuid)
    .bind(&data.name)
    .bind(&data.description)
    .bind(&data.start_date)
    .bind(&data.end_date)
    .bind(&data.r#type)
    .bind(&data.value_1)
    .bind(value_2)
    .execute(&mut **db).await
    .unwrap();

  if let Some(items) = &data.items {
    let query_string: Vec<String> = (0..items.len()).map(|i| format!("${}", i + 2)).collect();
    let query_string: String = format!("UPDATE items SET deal_uuid = $1 WHERE uuid IN ({})", query_string.join(", "));

    let mut query = sqlx::query(&query_string).bind(&uuid);
    for item in items {
      query = query.bind(item);
    }

    query.execute(&mut **db).await.unwrap();
  }

  Ok(Json(uuid))
}
