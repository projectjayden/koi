use crate::{ models::stores::Item, utils::{ functions::get_unix_seconds, search::{ item_search, DistanceFilter, PriceFilter } } };
use rocket::{ http::Status, serde::{ json::{ to_string, Json }, Deserialize } };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::{ sqlx::{ self, SqliteConnection }, Connection };
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct ItemInput {
  /// Whether the item is a UUID or just a name.
  is_uuid: bool,
  /// Either:
  ///
  /// An item UUID, or
  ///
  /// An item name that will be converted to an item UUID
  /// using the first result from the default item search algorithm.
  item: String,
  /// The quantity of the item to add to the list.
  ///
  /// Maximum of `99`.
  quantity: u8,
}

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct ListInput {
  /// GPS coordinate of the user's current location.
  ///
  /// Used when determining the closest items to the user.
  ///
  /// Can be omitted if all items are in the form of UUIDs.
  ///
  /// Format: `<latitude>, <longitude>`
  pub geolocation: Option<String>,
  /// See ItemInput for more information.
  pub items: Vec<ItemInput>,
}

/// # Create a List
/// **Route**: /user/list/create
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   items: {
///     isUuid: true;
///     item: string; // only uuid
///     quantity: number;
///   }[];
/// } | {
///   geolocation: string;
///   items: {
///     isUuid: boolean;
///     item: string; // uuid or name
///     quantity: number;
///   }[];
/// }
/// ```
///
/// **Output**:
/// - `string` (The list's UUID)
/// - 400 (geolocation not given but not all items are uuids, or a quantity is greater than 99)
/// - 403 (an item cant be found)
#[post("/create", data = "<data>")]
pub async fn create(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<ListInput>) -> Result<String, Status> {
  let mapped_items: Vec<(u8, String)> = match map_items(&mut **db, data.0).await {
    Ok(mapped_items) => mapped_items,
    Err(status) => {
      return Err(status);
    }
  };

  let uuid: String = uuid::Uuid::new_v4().to_string();

  sqlx
    ::query("INSERT INTO lists (uuid, user_uuid, created_at, last_updated, items) VALUES ($1, $2, $3, $3, $4)")
    .bind(&uuid)
    .bind(&user.0.uuid)
    .bind(get_unix_seconds() as u32)
    .bind(to_string(&mapped_items).unwrap())
    .execute(&mut **db).await
    .unwrap();

  Ok(uuid)
}

pub async fn map_items(db: &mut SqliteConnection, data: ListInput) -> Result<Vec<(u8, String)>, Status> {
  let mut mapped_items: Vec<(u8, String)> = vec![];

  if data.geolocation.is_some() {
    let (latitude, longitude) = match
      data.geolocation
        .unwrap()
        .split(", ")
        .map(|str: &str| str.parse::<f32>().unwrap())
        .collect::<Vec<f32>>()
        .as_slice()
    {
      [lat, long] => (*lat, *long),
      _ => {
        return Err(Status::InternalServerError);
      }
    };

    for list_item in data.items.into_iter() {
      if list_item.quantity > 99 {
        return Err(Status::BadRequest);
      }

      if list_item.is_uuid {
        mapped_items.push((list_item.quantity, list_item.item));
      } else {
        let (_, items) = item_search(&mut *db, &list_item.item, PriceFilter::All, DistanceFilter::All, 1, 0, latitude, longitude).await;
        let item: Option<&Item> = items.get(0);
        if item.is_none() {
          return Err(Status::BadRequest);
        }
        let item: &Item = item.unwrap();
        mapped_items.push((list_item.quantity, item.uuid.clone()));
      }
    }
  } else {
    for list_item in data.items.into_iter() {
      if list_item.is_uuid {
        mapped_items.push((list_item.quantity, list_item.item));
      } else {
        return Err(Status::BadRequest);
      }
    }
  }

  Ok(mapped_items)
}
