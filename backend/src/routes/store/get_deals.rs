use crate::{ guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore }, models::stores::Deal };
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
///   storeUuid: string;
///   name: string;
///   description: string | null;
///   startDate: number;
///   endDate: number;
///   type: number;
///   value1: number;
///   value2: number | null;
/// }[];
/// ```
#[get("/get-deals")]
pub async fn get_deals(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore) -> Json<Vec<Deal>> {
  Json(store.0.get_deals(&mut **db).await)
}
