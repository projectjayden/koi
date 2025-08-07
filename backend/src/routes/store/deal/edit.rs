use crate::{ guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore }, models::stores::Deal };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct CreateDealInput {
  /// Name of the deal.
  name: Option<String>,
  /// Description of the deal.
  description: Option<String>,
  /// Start date of the deal, as a unix timestamp in seconds.
  start_date: Option<u32>,
  /// End date of the deal, as a unix timestamp in seconds.
  end_date: Option<u32>,
  /// Type of deal.
  ///
  /// - 0 = `X`% off
  /// - 1 = Buy `X`, get `Y`
  /// - 2 = Buy `X`, get `Y`% off
  /// - 3 = Spend `X`, get `Y`
  /// - 4 = Spend `X`, get `Y`% off
  ///
  /// `X` is the value of `value_1` and `Y` is the value of `value_2`.
  r#type: Option<u8>,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  value_1: Option<u8>,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  ///
  /// Automatically removed from the deal's data if `type` is 0.
  value_2: Option<u8>,
}

/// # Edit a Deal
/// **Route**: /store/deal/edit/<uuid>
///
/// **Request method**: PATCH
///
/// **Input**: Same as /store/deal/create (minus `items`) but everything is optional
///
/// **Output**:
/// - 200 (success)
/// - 401 (deal not owned)
/// - 404 (deal not found)
#[patch("/edit/<uuid>", data = "<data>")]
pub async fn edit(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, uuid: &str, data: Json<CreateDealInput>) -> Status {
  let store_uuid: Option<String> = sqlx
    ::query("SELECT store_uuid FROM deals WHERE uuid = $1")
    .bind(&uuid)
    .fetch_one(&mut **db).await
    .and_then(|row: SqliteRow| Ok(row.try_get::<String, _>("store_uuid").unwrap()))
    .ok();
  if let None = store_uuid {
    return Status::NotFound;
  }

  let store_uuid: String = store_uuid.unwrap();
  if store_uuid != store.0.uuid {
    return Status::Unauthorized;
  }

  let existing_deal: Option<Deal> = Deal::from_uuid(&mut **db, uuid.to_string()).await;
  if existing_deal.is_none() {
    return Status::NotFound;
  }
  let existing_deal: Deal = existing_deal.unwrap();

  let name: String = data.0.name.unwrap_or(existing_deal.name);
  let description: Option<String> = data.0.description.or(existing_deal.description);
  let start_date: u32 = data.0.start_date.unwrap_or(existing_deal.start_date);
  let end_date: u32 = data.0.end_date.unwrap_or(existing_deal.end_date);
  let r#type: u8 = data.0.r#type.unwrap_or(existing_deal.r#type);
  let value_1: u8 = data.0.value_1.unwrap_or(existing_deal.value_1);
  let value_2: Option<u8> = data.0.value_2.or(existing_deal.value_2);
  let value_2: Option<u8> = if r#type == 0 { None } else { value_2 };

  sqlx
    ::query("UPDATE deals SET name = $1, description = $2, start_date = $3, end_date = $4, type = $5, value_1 = $6, value_2 = $7 WHERE uuid = $8")
    .bind(&name)
    .bind(&description)
    .bind(&start_date)
    .bind(&end_date)
    .bind(&r#type)
    .bind(&value_1)
    .bind(&value_2)
    .bind(&uuid)
    .execute(&mut **db).await
    .unwrap();

  Status::Ok
}
