use crate::{ models::stores::Deal, utils::functions::get_from_row };
use rocket_db_pools::sqlx::{ self, SqliteConnection };
use rocket::serde::Serialize;

#[derive(Serialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct SerializedItem {
  /// UUID of the item.
  pub uuid: String,
  /// Name of the item.
  pub name: String,
  /// Price of the item, in USD.
  pub price: f32,
  /// Name of the manufacturer of the item.
  pub manufacturer: Option<String>,
  /// Whether the item is currently in stock at its store.
  pub in_stock: bool,
  /// UUID of the item's store.
  pub store_uuid: String,
  /// Data about the item's deal.
  ///
  /// Each item can only be a part of one deal.
  pub deal: Option<Deal>,
  /// JSON blob of the item's image.
  pub image: Option<String>,
}

pub struct Item {
  /// UUID of the item.
  pub uuid: String,
  /// Name of the item.
  pub name: String,
  /// Price of the item, in USD.
  pub price: f32,
  /// Name of the manufacturer of the item.
  pub manufacturer: Option<String>,
  /// Whether the item is currently in stock at its store.
  pub in_stock: bool,
  /// UUID of the item's store.
  pub store_uuid: String,
  /// UUID of a deal associated with this item.
  ///
  /// Each item can only be a part of one deal.
  pub deal_uuid: Option<String>,
  /// JSON blob of the item's image.
  pub image: Option<String>,
}

impl Item {
  pub fn new(uuid: String, name: String, price: f32, manufacturer: Option<String>, in_stock: bool, store_uuid: String, deal_uuid: Option<String>, image: Option<String>) -> Self {
    Self {
      uuid,
      name,
      price,
      manufacturer,
      in_stock,
      store_uuid,
      deal_uuid,
      image,
    }
  }

  pub async fn serialize(&self, db: &mut SqliteConnection) -> SerializedItem {
    SerializedItem {
      uuid: self.uuid.clone(),
      name: self.name.clone(),
      price: self.price,
      manufacturer: self.manufacturer.clone(),
      in_stock: self.in_stock,
      store_uuid: self.store_uuid.clone(),
      deal: if self.deal_uuid.is_some() {
        Some(Deal::from_uuid(&mut *db, self.deal_uuid.as_ref().unwrap().to_string()).await.unwrap())
      } else {
        None
      },
      image: self.image.clone(),
    }
  }

  pub async fn from_uuid(db: &mut SqliteConnection, uuid: String) -> Option<Self> {
    sqlx
      ::query("SELECT * FROM items WHERE uuid = $1")
      .bind(&uuid)
      .fetch_one(&mut *db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| {
        Ok(
          Self::new(
            get_from_row(&row, "uuid"),
            get_from_row(&row, "name"),
            get_from_row(&row, "price"),
            get_from_row(&row, "manufacturer"),
            get_from_row(&row, "in_stock"),
            get_from_row(&row, "store_uuid"),
            get_from_row(&row, "deal_uuid"),
            get_from_row(&row, "image")
          )
        )
      })
      .ok()
  }
}
