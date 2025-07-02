use rocket::{ serde::{ Deserialize, Serialize } };

#[derive(Deserialize, Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedUser {
  /// Public-facing user ID.
  pub uuid: String,
  /// User's email address.
  pub email: String,
  /// The last time the user has logged in, as a unix timestamp.
  pub last_login: u32,
  /// The user's join date, as a unix timestamp.
  pub date_joined: u32,
  /// If the user is associated with a store, the store's ID.
  pub store_id: Option<u32>,
  /// Whether the user is a paying subscriber. Defaults to `false`.
  pub is_subscribed: bool,
  /// Whether the user has deal alerts enabled. Defaults to `true`.
  pub deal_alert_active: bool,
  /// Radius of the user's deal alerts, in miles. Defaults to `20`. Min of `1`, max of `200`.
  pub deal_alert_radius: u8,
  /// Text string of any user preferences (halal, vegan, etc). Used with LLM to generate recommendations.
  pub preferences: String
}

pub struct User {
  /// Internal user ID, incremented by 1 for each user created.
  id: u32,
  /// Public-facing user ID.
  pub uuid: String,
  /// User's email address.
  pub email: String,
  /// User's encrypted password.
  pub password: String,
  /// The last time the user has logged in, as a unix timestamp.
  pub last_login: u32,
  /// The user's join date, as a unix timestamp.
  pub date_joined: u32,
  /// If the user is associated with a store, the store's ID.
  pub store_id: Option<u32>,
  /// Whether the user is a paying subscriber. Defaults to `false`.
  pub is_subscribed: bool,
  /// Whether the user has deal alerts enabled. Defaults to `true`.
  pub deal_alert_active: bool,
  /// Radius of the user's deal alerts, in miles. Defaults to `20`. Min of `1`, max of `200`.
  pub deal_alert_radius: u8,
  /// Text string of any user preferences (halal, vegan, etc). Used with LLM to generate recommendations.
  pub preferences: String
}
impl User {
  /// Creates a new user.
  /// 
  /// # Arguments
  /// 
  /// * `is_subscribed` - 0 or 1
  /// * `deal_alert_active` - 0 or 1
  pub fn new(id: u32, uuid: String, email: String, password: String, last_login: u32, date_joined: u32, store_id: Option<u32>, is_subscribed: u8, deal_alert_active: u8, deal_alert_radius: u8, preferences: String) -> Self {
    Self {
      id,
      uuid,
      email,
      password,
      last_login,
      date_joined,
      store_id,
      is_subscribed: is_subscribed == 1,
      deal_alert_active: deal_alert_active == 1,
      deal_alert_radius,
      preferences
    }
  }

  pub fn serialize(&self) -> SerializedUser {
    SerializedUser {
      uuid: self.uuid.clone(),
      email: self.email.clone(),
      last_login: self.last_login,
      date_joined: self.date_joined,
      store_id: self.store_id,
      is_subscribed: self.is_subscribed,
      deal_alert_active: self.deal_alert_active,
      deal_alert_radius: self.deal_alert_radius,
      preferences: self.preferences.clone()
    }
  }
}