use crate::guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore };
use rocket_db_pools::{ sqlx::{ self, sqlite::SqliteRow }, Connection };
use crate::guards::json_limit::LimitedJson;
use crate::utils::functions::get_from_row;
use rocket::serde::Deserialize;
use rocket::serde::json::Json;
use rocket::http::Status;
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
pub async fn create(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, data: LimitedJson<Vec<CreateItemInput>>) -> Result<Json<Vec<String>>, Status> {
  let uuids: Vec<String> = data.0
    .iter()
    .map(|_| Uuid::new_v4().to_string())
    .collect();

  for (i, uuid) in uuids.iter().enumerate() {
    let item: &&CreateItemInput = &data.0.get(i).unwrap();

    if item.deal_uuid.is_some() {
      let deal_is_owned: bool = sqlx
        ::query("SELECT store_uuid FROM deals WHERE uuid = $1")
        .bind(item.deal_uuid.as_ref().unwrap())
        .fetch_one(&mut **db).await
        .and_then(|row: SqliteRow| { Ok(get_from_row::<String>(&row, "store_uuid") == store.0.uuid) })
        .unwrap();
      if !deal_is_owned {
        return Err(Status::Unauthorized);
      }
    }

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

  Ok(Json(uuids))
}
