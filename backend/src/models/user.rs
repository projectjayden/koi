use rocket::{ serde::{ Deserialize, Serialize } };

#[derive(Deserialize, Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedUser {
  /// Public-facing user ID.
  pub uuid: String,
  pub email: String,
  pub last_login: u32,
  pub date_joined: u32,
  pub store_id: Option<u32>
}

pub struct User {
  /// Internal user ID, incremented by 1 for each user created.
  id: u32,
  /// Public-facing user ID.
  pub uuid: String,
  pub email: String,
  /// User's encrypted password.
  pub password: String,
  pub last_login: u32,
  pub date_joined: u32,
  pub store_id: Option<u32>
}
impl User {
  pub fn new(id: u32, uuid: String, email: String, password: String, last_login: u32, date_joined: u32, store_id: Option<u32>) -> Self {
    Self {
      id,
      uuid,
      email,
      password,
      last_login,
      date_joined,
      store_id
    }
  }

  pub fn serialize(&self) -> SerializedUser {
    SerializedUser {
      uuid: self.uuid.clone(),
      email: self.email.clone(),
      last_login: self.last_login,
      date_joined: self.date_joined,
      store_id: self.store_id
    }
  }
}