use rocket::serde::Serialize;

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedReview {
  pub user_uuid: String,
  pub store_uuid: String,
  /// Unix timestamp of when the review was created, in seconds.
  pub created_at: u32,
  /// Star rating between `0.0` and `5.0`, inclusive.
  pub rating: f32,
  pub description: Option<String>,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct Review {
  id: u32,
  pub user_uuid: String,
  pub store_uuid: String,
  /// Unix timestamp of when the review was created, in seconds.
  pub created_at: u32,
  /// Star rating between `0.0` and `5.0`, inclusive.
  pub rating: f32,
  pub description: Option<String>,
}

impl Review {
  pub fn new(id: u32, user_uuid: String, store_uuid: String, created_at: u32, rating: f32, description: Option<String>) -> Self {
    Self {
      id,
      user_uuid,
      store_uuid,
      created_at,
      rating,
      description,
    }
  }

  pub fn serialize(&self) -> SerializedReview {
    SerializedReview {
      user_uuid: self.user_uuid.clone(),
      store_uuid: self.store_uuid.clone(),
      created_at: self.created_at,
      rating: self.rating,
      description: self.description.clone(),
    }
  }
}
