use rocket::serde::Serialize;

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
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
  /// UUID of a deal associated with this item.
  ///
  /// Each item can only be a part of one deal.
  pub deal_uuid: Option<String>,
  /// JSON blob of the item's image.
  pub image: Option<String>,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct Item {
  /// Internal item ID, incremented by 1 for each item created.
  id: u32,
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
  pub fn new(id: u32, uuid: String, name: String, price: f32, manufacturer: Option<String>, in_stock: bool, store_uuid: String, deal_uuid: Option<String>, image: Option<String>) -> Self {
    Self {
      id,
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

  pub fn serialize(&self) -> SerializedItem {
    SerializedItem {
      uuid: self.uuid.clone(),
      name: self.name.clone(),
      price: self.price,
      manufacturer: self.manufacturer.clone(),
      in_stock: self.in_stock,
      store_uuid: self.store_uuid.clone(),
      deal_uuid: self.deal_uuid.clone(),
      image: self.image.clone(),
    }
  }
}
