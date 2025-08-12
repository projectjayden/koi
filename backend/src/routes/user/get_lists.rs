use crate::{ guards::auth::AuthenticatedUser, models::users::list::SerializedList };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct ListInput {
  /// Number of lists to get.
  ///
  /// Defaults to `20`.
  pub limit: Option<u32>,
  /// Offset of lists.
  ///
  /// Defaults to `0`.
  pub offset: Option<u32>,
}

/// # Get Lists
/// **Route**: /user/get-lists
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   limit?: number;
///   offset?: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// [
///   number; // total lists
///   {
///     uuid: number;
///     userUuid: number;
///     createdAt: number;
///     lastUpdated: number;
///     items: [
///       number, // quantity
///       {
///         uuid: string;
///         name: string;
///         price: number;
///         manfuacturer: string | null;
///         inStock: boolean;
///         storeUuid: string;
///         deal: { /* deal object */ } | null;
///         image: string | null;
///       }
///     ][];
///   }[];
/// ]
/// ```
#[post("/get-lists", data = "<data>")]
pub async fn get_lists(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<ListInput>) -> Result<Json<(usize, Vec<SerializedList>)>, Status> {
  let limit: u32 = data.0.limit.unwrap_or(20);
  let offset: u32 = data.0.offset.unwrap_or(0);

  let (total_lists, lists) = user.0.get_lists(&mut db, limit, offset).await;

  let mut serialized_lists: Vec<SerializedList> = vec![];
  for list in lists {
    serialized_lists.push(list.serialize(&mut **db).await);
  }

  Ok(Json((total_lists, serialized_lists)))
}
