use crate::guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore };
use crate::guards::json_limit::LimitedJson;
use rocket_db_pools::{ sqlx, Connection };
use rocket::serde::Deserialize;
use rocket::serde::json::Json;
use crate::utils::db::Db;
use uuid::Uuid;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct CreateItemInput {
  /// Name of the item.
  name: String,
  /// Price of the item, in USD.
  price: f32,
  /// Name of the manufacturer of the item.
  manufacturer: Option<String>,
  /// Whether the item is in stock.
  in_stock: bool,
  /// Image of the item, as a JSON blob.
  image: Option<String>,
  /// UUID of the deal associated with the item.
  deal_uuid: Option<String>,
}

/// # Create Items
/// **Route**: /store/item/create
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   name: string;
///   price: number;
///   manufacturer?: string;
///   inStock: boolean;
///   image?: string;
///   dealUuid?: string
/// }[]; // array of items
/// ```
///
/// **Output**:
/// - `string[]` - UUIDs of the created items, in the same order as input array
#[post("/create", data = "<data>")]
pub async fn create(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, data: LimitedJson<Vec<CreateItemInput>>) -> Json<Vec<String>> {
  let uuids: Vec<String> = data.0
    .iter()
    .map(|_| Uuid::new_v4().to_string())
    .collect();

  for (i, uuid) in uuids.iter().enumerate() {
    let item: &&CreateItemInput = &data.0.get(i).unwrap();

    sqlx
      ::query("INSERT INTO items (uuid, name, price, manufacturer, in_stock, store_uuid, deal_uuid, image) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)")
      .bind(&uuid)
      .bind(&item.name)
      .bind(&item.price.to_string())
      .bind(&item.manufacturer)
      .bind(&item.in_stock)
      .bind(&store.0.uuid)
      .bind(&item.deal_uuid)
      .bind(&item.image)
      .execute(&mut **db).await
      .unwrap();
  }

  Json(uuids)
}
