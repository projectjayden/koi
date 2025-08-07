use crate::{ guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore }, models::stores::{ Item, SerializedItem } };
use rocket_db_pools::Connection;
use rocket::serde::json::Json;
use crate::utils::db::Db;

/// # Get Items
/// **Route**: /store/get-items
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// ```ts
/// {
///   uuid: string;
///   name: string;
///   price: number;
///   manufacturer: string | null;
///   in_stock: boolean;
///   store_uuid: string;
///   deal: {
///     uuid: string;
///     store_uuid: string;
///     name: string;
///     description: string | null;
///     start_date: number;
///     end_date: number;
///     type: number;
///     value_1: number;
///     value_2: number | null;
///   } | null;
///   image: string | null;
/// }[];
/// ```
#[get("/get-items")]
pub async fn get_items(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore) -> Json<Vec<SerializedItem>> {
  let items: Vec<Item> = store.0.get_items(&mut **db).await;

  let mut serialized_items: Vec<SerializedItem> = vec![];
  for item in items {
    serialized_items.push(item.serialize(&mut **db).await);
  }

  Json(serialized_items)
}
