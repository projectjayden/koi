use rocket::serde::Serialize;

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedUserReview {
  pub user_uuid: String,
  pub store_uuid: String,
  /// Star rating between `0.0` and `5.0`, inclusive.
  pub rating: f32,
  pub description: String,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct UserReview {
  id: u32,
  pub user_uuid: String,
  pub store_uuid: String,
  /// Star rating between `0.0` and `5.0`, inclusive.
  pub rating: f32,
  pub description: String,
}

impl UserReview {
  pub fn new(id: u32, user_uuid: String, store_uuid: String, rating: f32, description: String) -> Self {
    Self {
      id,
      user_uuid,
      store_uuid,
      rating,
      description,
    }
  }

  pub async fn serialize(&self) -> SerializedUserReview {
    SerializedUserReview {
      user_uuid: self.user_uuid.clone(),
      store_uuid: self.store_uuid.clone(),
      rating: self.rating,
      description: self.description.clone(),
    }
  }
}
