use rocket::serde::Serialize;
use rocket_db_pools::sqlx::{ self, SqliteConnection };
use crate::utils::functions::get_from_row;

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedDeal {
  /// UUID of the deal.
  pub uuid: String,
  /// UUID of the store associated with the deal.
  pub store_uuid: String,
  /// Name of the deal.
  pub name: String,
  /// Description of the deal.
  pub description: Option<String>,
  /// Unix timestamp of when the deal starts, in seconds.
  pub start_date: u32,
  /// Unix timestamp of when the deal ends, in seconds.
  pub end_date: u32,
  /// Type of deal.
  ///
  /// - 0 = `X`% off
  /// - 1 = Buy `X`, get `Y` free
  /// - 2 = Buy `X`, get `Y`% off
  /// - 3 = Spend $`X`, get `Y` free
  /// - 4 = Spend $`X`, get `Y`% off
  ///
  /// `X` is the value of `value_1` and `Y` is the value of `value_2`.
  pub r#type: u8,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  pub value_1: u8,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  pub value_2: Option<u8>,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct Deal {
  /// Internal deal ID, incremented by 1 for each deal created.
  id: u32,
  /// UUID of the deal.
  pub uuid: String,
  /// UUID of the store associated with the deal.
  pub store_uuid: String,
  /// Name of the deal.
  pub name: String,
  /// Description of the deal.
  pub description: Option<String>,
  /// Unix timestamp of when the deal starts, in seconds.
  pub start_date: u32,
  /// Unix timestamp of when the deal ends, in seconds.
  pub end_date: u32,
  /// Type of deal.
  ///
  /// - 0 = `X`% off
  /// - 1 = Buy `X`, get `Y`
  /// - 2 = Buy `X`, get `Y`% off
  /// - 3 = Spend `X`, get `Y`
  /// - 4 = Spend `X`, get `Y`% off
  ///
  /// `X` is the value of `value_1` and `Y` is the value of `value_2`.
  pub r#type: u8,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  pub value_1: u8,
  /// See `type` for details.
  ///
  /// Maximum value of 250.
  pub value_2: Option<u8>,
}

impl Deal {
  pub fn new(id: u32, uuid: String, store_uuid: String, name: String, description: Option<String>, start_date: u32, end_date: u32, r#type: u8, value_1: u8, value_2: Option<u8>) -> Self {
    Self {
      id,
      uuid,
      store_uuid,
      name,
      description,
      start_date,
      end_date,
      r#type,
      value_1,
      value_2,
    }
  }

  pub fn serialize(&self) -> SerializedDeal {
    SerializedDeal {
      uuid: self.uuid.clone(),
      store_uuid: self.store_uuid.clone(),
      name: self.name.clone(),
      description: self.description.clone(),
      start_date: self.start_date,
      end_date: self.end_date,
      r#type: self.r#type,
      value_1: self.value_1,
      value_2: self.value_2,
    }
  }

  pub async fn from_uuid(db: &mut SqliteConnection, uuid: String) -> Option<Self> {
    sqlx
      ::query("SELECT * FROM deals WHERE uuid = $1")
      .bind(uuid)
      .fetch_one(&mut *db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| {
        Ok(
          Self::new(
            get_from_row(&row, "id"),
            get_from_row(&row, "uuid"),
            get_from_row(&row, "store_uuid"),
            get_from_row(&row, "name"),
            get_from_row(&row, "description"),
            get_from_row(&row, "start_date"),
            get_from_row(&row, "end_date"),
            get_from_row(&row, "type"),
            get_from_row(&row, "value_1"),
            get_from_row(&row, "value_2")
          )
        )
      })
      .ok()
  }
}
