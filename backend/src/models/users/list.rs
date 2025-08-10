use crate::{ models::stores::{ Item, SerializedItem }, utils::functions::get_from_row };
use rocket_db_pools::sqlx::{ self, SqliteConnection, sqlite::SqliteRow };
use rocket::serde::Serialize;

#[derive(Serialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct SerializedList {
  /// List UUID.
  pub uuid: String,
  /// User UUID of the author of the list.
  pub user_uuid: String,
  /// Unix timestamp of when the list was created, in seconds.
  pub created_at: u32,
  /// Unix timestamp of when the list was last updated, in seconds.
  pub last_updated: u32,
  /// Array of items.
  pub items: Vec<SerializedItem>,
}

pub struct List {
  /// List UUID.
  pub uuid: String,
  /// User UUID of the author of the list.
  pub user_uuid: String,
  /// Unix timestamp of when the list was created, in seconds.
  pub created_at: u32,
  /// Unix timestamp of when the list was last updated, in seconds.
  pub last_updated: u32,
  /// Array of item UUIDs.
  pub items: Vec<String>,
}
impl List {
  pub fn new(uuid: String, user_uuid: String, created_at: u32, last_updated: u32, items: Vec<String>) -> Self {
    Self {
      uuid,
      user_uuid,
      created_at,
      last_updated,
      items,
    }
  }

  pub async fn serialize(&self, db: &mut SqliteConnection) -> SerializedList {
    // * using .bind doesnt query correctly for some reason ??
    let items: Vec<Item> = sqlx
      ::query(&format!("SELECT * FROM items WHERE uuid IN (\"{}\")", self.items.join("\", \"")))
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<sqlx::sqlite::SqliteRow>| {
        rows
          .into_iter()
          .map(|row: SqliteRow| {
            let uuid: String = get_from_row(&row, "uuid");
            let name: String = get_from_row(&row, "name");
            let price: f32 = get_from_row(&row, "price");
            let manufacturer: Option<String> = get_from_row(&row, "manufacturer");
            let in_stock: bool = get_from_row(&row, "in_stock");
            let store_uuid: String = get_from_row(&row, "store_uuid");
            let deal_uuid: Option<String> = get_from_row(&row, "deal_uuid");
            let image: Option<String> = get_from_row(&row, "image");
            Ok(Item::new(uuid, name, price, manufacturer, in_stock, store_uuid, deal_uuid, image))
          })
          .collect()
      })
      .unwrap();

    let mut serialized_items: Vec<SerializedItem> = vec![];
    for item in items {
      serialized_items.push(item.serialize(&mut *db).await);
    }

    SerializedList {
      uuid: self.uuid.clone(),
      user_uuid: self.user_uuid.clone(),
      created_at: self.created_at,
      last_updated: self.last_updated,
      items: serialized_items,
    }
  }
}
