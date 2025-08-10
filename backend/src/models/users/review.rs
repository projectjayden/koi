use rocket::serde::Serialize;

#[derive(Serialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct Review {
  pub user_uuid: String,
  pub store_uuid: String,
  /// Unix timestamp of when the review was created, in seconds.
  pub created_at: u32,
  /// Star rating between `0.0` and `5.0`, inclusive.
  pub rating: f32,
  pub description: Option<String>,
}

impl Review {
  pub fn new(user_uuid: String, store_uuid: String, created_at: u32, rating: f32, description: Option<String>) -> Self {
    Self {
      user_uuid,
      store_uuid,
      created_at,
      rating,
      description,
    }
  }
}
