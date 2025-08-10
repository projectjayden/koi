use crate::guards::{ auth::AuthenticatedUser, json_limit::LimitedJson, store_auth::AuthenticatedStore };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use rocket::{ http::Status, serde::Deserialize };
use crate::models::stores::Item;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct CreateItemInput {
  /// Name of the item.
  name: Option<String>,
  /// Price of the item, in USD.
  price: Option<f32>,
  /// Name of the manufacturer of the item.
  manufacturer: Option<String>,
  /// Whether the item is in stock.
  in_stock: Option<bool>,
  /// Image of the item, as a JSON blob.
  image: Option<String>,
  /// UUID of the deal associated with the item.
  deal_uuid: Option<String>,
}

/// # Edit an Item
/// **Route**: /store/item/edit/<uuid>
///
/// **Request method**: PATCH
///
/// **Input**: Same as /store/item/create but not an array and everything is optional
///
/// **Output**:
/// - 200 (success)
/// - 401 (item not owned)
/// - 404 (item not found)
#[patch("/edit/<uuid>", data = "<data>")]
pub async fn edit(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, uuid: &str, data: LimitedJson<CreateItemInput>) -> Status {
  let store_uuid: Option<String> = sqlx
    ::query("SELECT store_uuid FROM items WHERE uuid = $1")
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

  let existing_item: Option<Item> = Item::from_uuid(&mut **db, uuid.to_string()).await;
  if existing_item.is_none() {
    return Status::NotFound;
  }
  let existing_item: Item = existing_item.unwrap();

  let name: String = data.0.name.unwrap_or(existing_item.name);
  let price: f32 = data.0.price.unwrap_or(existing_item.price);
  let manufacturer: Option<String> = data.0.manufacturer.or(existing_item.manufacturer);
  let in_stock: bool = data.0.in_stock.unwrap_or(existing_item.in_stock);
  let image: Option<String> = data.0.image.or(existing_item.image);
  let deal_uuid: Option<String> = data.0.deal_uuid.or(existing_item.deal_uuid);

  sqlx
    ::query("UPDATE items SET name = $1, price = $2, manufacturer = $3, in_stock = $4, image = $5, deal_uuid = $6 WHERE uuid = $7")
    .bind(&name)
    .bind(&price)
    .bind(&manufacturer)
    .bind(&in_stock)
    .bind(&image)
    .bind(&deal_uuid)
    .bind(&uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
