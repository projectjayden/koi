use rocket_db_pools::sqlx::{ self, Row, SqliteConnection };
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

  pub async fn serialize(&self, db: &mut SqliteConnection) -> SerializedUserReview {
    let user_uuid: String = sqlx
      ::query("SELECT uuid FROM users WHERE uuid = ?")
      .bind(&self.user_uuid)
      .fetch_one(&mut *db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| { row.try_get::<String, _>("uuid") })
      .unwrap();
    let store_uuid: String = sqlx
      ::query("SELECT uuid FROM stores WHERE uuid = ?")
      .bind(&self.user_uuid)
      .fetch_one(db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| { row.try_get::<String, _>("uuid") })
      .unwrap();

    SerializedUserReview {
      user_uuid,
      store_uuid,
      rating: self.rating,
      description: self.description.clone(),
    }
  }
}
