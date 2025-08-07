use crate::{ guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore }, models::stores::SerializedDeal };
use rocket_db_pools::Connection;
use rocket::serde::json::Json;
use crate::utils::db::Db;

/// # Get Deals
/// **Route**: /store/get-deals
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// ```ts
/// {
///   uuid: string;
///   store_uuid: string;
///   name: string;
///   description: string | null;
///   start_date: number;
///   end_date: number;
///   type: number;
///   value_1: number;
///   value_2: number | null;
/// }[];
/// ```
#[get("/get-deals", format = "json")]
pub async fn get_deals(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore) -> Json<Vec<SerializedDeal>> {
  Json(
    store.0
      .get_deals(&mut **db).await
      .into_iter()
      .map(|deal| deal.serialize())
      .collect()
  )
}
