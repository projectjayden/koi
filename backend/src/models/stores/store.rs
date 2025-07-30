use rocket_db_pools::sqlx::{ self, Row, SqliteConnection, Sqlite, Error };
use rocket::{ serde::{ Deserialize, Serialize } };

use crate::models::stores::{ Deal, Item, StoreReview };

#[derive(Deserialize, Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedStore {
  /// Store UUID.
  pub uuid: String,
  /// Store's name.
  pub name: String,
  /// Latitude of the store location.
  pub latitude: f32,
  /// Longitude of the store location.
  pub longitude: f32,
  /// Store's contact phone number.
  pub phone: Option<String>,
  /// Store's contact email address.
  pub email: Option<String>,
  /// 7x2 array representing open hours.
  ///
  /// The first tuple is Monday, then Tuesday, etc, ending on Sunday.
  ///
  /// The first value of each tuple is the open time, the second is the closing time.
  ///
  /// Time is in 24-hour format, with colons and leading 0s.
  pub open_hours: Option<[(String, String); 7]>,
}

#[derive(Deserialize, Serialize)]
#[serde(crate = "rocket::serde")]
pub struct Store {
  /// Internal store ID, incremented by 1 for each store created.
  id: u32,
  /// Store UUID.
  pub uuid: String,
  /// Store's name.
  pub name: String,
  /// Latitude of the store location.
  pub latitude: f32,
  /// Longitude of the store location.
  pub longitude: f32,
  /// Store's contact phone number.
  pub phone: Option<String>,
  /// Store's contact email address.
  pub email: Option<String>,
  /// 7x2 array representing open hours.
  ///
  /// The first tuple is Monday, then Tuesday, etc, ending on Sunday.
  ///
  /// The first value of each tuple is the open time, the second is the closing time.
  ///
  /// Time is in 24-hour format, with colons and leading 0s.
  pub open_hours: Option<[(String, String); 7]>,
}
impl Store {
  fn get_from_row<'a, T: sqlx::Decode<'a, Sqlite> + sqlx::Type<Sqlite>>(row: &'a sqlx::sqlite::SqliteRow, column: &str) -> T {
    row.try_get::<T, _>(column).unwrap()
  }

  /// Creates a new store.
  pub async fn new(db: &mut SqliteConnection, uuid: String) -> Option<Self> {
    sqlx
      ::query("SELECT * FROM stores WHERE uuid = $1")
      .bind(uuid)
      .fetch_one(db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| {
        let id: u32 = Self::get_from_row::<u32>(&row, "id");
        let uuid: String = Self::get_from_row(&row, "uuid");
        let name: String = Self::get_from_row(&row, "name");
        let latitude: f32 = Self::get_from_row(&row, "latitude");
        let longitude: f32 = Self::get_from_row(&row, "longitude");
        let phone: Option<String> = Self::get_from_row(&row, "phone");
        let email: Option<String> = Self::get_from_row(&row, "email");
        let open_mon: Option<String> = Self::get_from_row(&row, "open_mon");
        let close_mon: Option<String> = Self::get_from_row(&row, "close_mon");
        let open_tue: Option<String> = Self::get_from_row(&row, "open_tue");
        let close_tue: Option<String> = Self::get_from_row(&row, "close_tue");
        let open_wed: Option<String> = Self::get_from_row(&row, "open_wed");
        let close_wed: Option<String> = Self::get_from_row(&row, "close_wed");
        let open_thu: Option<String> = Self::get_from_row(&row, "open_thu");
        let close_thu: Option<String> = Self::get_from_row(&row, "close_thu");
        let open_fri: Option<String> = Self::get_from_row(&row, "open_fri");
        let close_fri: Option<String> = Self::get_from_row(&row, "close_fri");
        let open_sat: Option<String> = Self::get_from_row(&row, "open_sat");
        let close_sat: Option<String> = Self::get_from_row(&row, "close_sat");
        let open_sun: Option<String> = Self::get_from_row(&row, "open_sun");
        let close_sun: Option<String> = Self::get_from_row(&row, "close_sun");

        let open_hours: Option<[(String, String); 7]> = if open_mon.is_some() {
          Some([
            (open_mon.unwrap(), close_mon.unwrap()),
            (open_tue.unwrap(), close_tue.unwrap()),
            (open_wed.unwrap(), close_wed.unwrap()),
            (open_thu.unwrap(), close_thu.unwrap()),
            (open_fri.unwrap(), close_fri.unwrap()),
            (open_sat.unwrap(), close_sat.unwrap()),
            (open_sun.unwrap(), close_sun.unwrap()),
          ])
        } else {
          None
        };
        Ok(Self {
          id,
          uuid,
          name,
          latitude,
          longitude,
          phone,
          email,
          open_hours,
        })
      })
      .ok()
  }

  pub fn serialize(&self) -> SerializedStore {
    SerializedStore {
      uuid: self.uuid.clone(),
      name: self.name.clone(),
      latitude: self.latitude,
      longitude: self.longitude,
      phone: self.phone.clone(),
      email: self.email.clone(),
      open_hours: self.open_hours.clone(),
    }
  }

  /// Finds a store by its geolocation.
  pub async fn from_geolocation(db: &mut SqliteConnection, latitude: &str, longitude: &str) -> Option<Self> {
    let uuid: Option<String> = sqlx
      ::query("SELECT uuid FROM stores WHERE latitude = $1 AND longitude = $2")
      .bind(latitude)
      .bind(longitude)
      .fetch_one(&mut *db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| Ok(Self::get_from_row(&row, "uuid")))
      .ok();

    let uuid: String = match uuid {
      Some(uuid) => uuid,
      None => {
        return None;
      }
    };

    Self::new(db, uuid).await
  }

  /// Gets all items in the store's catalog.
  pub async fn get_items(&self, db: &mut SqliteConnection) -> Vec<Item> {
    sqlx
      ::query("SELECT * FROM items WHERE store_uuid = $1")
      .bind(&self.uuid)
      .fetch_all(db).await
      .unwrap()
      .into_iter()
      .map(|row: sqlx::sqlite::SqliteRow| {
        let id: u32 = Self::get_from_row(&row, "id");
        let uuid: String = Self::get_from_row(&row, "uuid");
        let name: String = Self::get_from_row(&row, "name");
        let price: f32 = Self::get_from_row(&row, "price");
        let manufacturer: Option<String> = Self::get_from_row(&row, "manufacturer");
        let in_stock: bool = Self::get_from_row(&row, "in_stock");
        let store_uuid: String = Self::get_from_row(&row, "store_uuid");
        let deal_uuid: Option<String> = Self::get_from_row(&row, "deal_uuid");
        let image: Option<String> = Self::get_from_row(&row, "image");
        Item::new(id, uuid, name, price, manufacturer, in_stock, store_uuid, deal_uuid, image)
      })
      .collect()
  }

  /// Gets all of the store's deals.
  pub async fn get_deals(&self, db: &mut SqliteConnection) -> Vec<Deal> {
    sqlx
      ::query("SELECT * FROM deals WHERE store_uuid = $1")
      .bind(&self.uuid)
      .fetch_all(db).await
      .unwrap()
      .into_iter()
      .map(|row: sqlx::sqlite::SqliteRow| {
        let id: u32 = Self::get_from_row(&row, "id");
        let uuid: String = Self::get_from_row(&row, "uuid");
        let name: String = Self::get_from_row(&row, "name");
        let description: Option<String> = Self::get_from_row(&row, "description");
        let start_date: u32 = Self::get_from_row(&row, "start_date");
        let end_date: u32 = Self::get_from_row(&row, "end_date");
        let r#type: u8 = Self::get_from_row(&row, "type");
        let value_1: u8 = Self::get_from_row(&row, "value_1");
        let value_2: Option<u8> = Self::get_from_row(&row, "value_2");
        Deal::new(id, uuid, self.uuid.clone(), name, description, start_date, end_date, r#type, value_1, value_2)
      })
      .collect()
  }

  /// Gets the store's reviews.
  ///
  /// ! These reviews are of users' reviews of the store.
  ///
  /// Returns `(total_reviews, reviews)``
  pub async fn get_reviews(&self, db: &mut SqliteConnection, limit: u32, offset: u32) -> (usize, Vec<StoreReview>) {
    sqlx
      ::query("SELECT * FROM store_reviews WHERE user_uuid = $1")
      .bind(&self.uuid)
      .fetch_all(db).await
      .and_then(|rows: Vec<sqlx::sqlite::SqliteRow>| {
        let num_of_reviews: usize = rows.len();
        if offset + limit > (num_of_reviews as u32) {
          return Err(Error::RowNotFound);
        }

        let mut reviews: Vec<StoreReview> = vec![];
        let reviews_to_get: u32 = offset + limit;
        for i in offset..reviews_to_get {
          let row: &sqlx::sqlite::SqliteRow = rows.get(i as usize).unwrap();

          let id: u32 = Self::get_from_row(row, "id");
          let user_uuid: String = Self::get_from_row(row, "user_uuid");
          let store_uuid: String = Self::get_from_row(row, "store_uuid");
          let rating: f32 = Self::get_from_row(row, "rating");
          let description: String = Self::get_from_row(row, "description");
          reviews.push(StoreReview::new(id, user_uuid, store_uuid, rating, description));
        }
        Ok((num_of_reviews, reviews))
      })
      .unwrap()
  }
}
