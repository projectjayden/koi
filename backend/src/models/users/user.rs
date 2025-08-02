use rocket_db_pools::sqlx::{ self, Row, Sqlite, SqliteConnection, Error };
use rocket::serde::{ Deserialize, Serialize };
use crate::models::stores::StoreReview;

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedUser {
  /// User UUID.
  pub uuid: String,
  /// User's name.
  pub name: String,
  /// User's biography for their profile.
  pub bio: String,
  /// User's email address.
  pub email: String,
  /// The last time the user has logged in, as a unix timestamp.
  pub last_login: u32,
  /// The user's join date, as a unix timestamp.
  pub date_joined: u32,
  /// If the user is associated with a store, the store's UUID.
  pub store_uuid: Option<String>,
  /// Whether the user is a paying subscriber. Defaults to `false`.
  pub is_subscribed: bool,
}

#[derive(Deserialize, Serialize)]
#[serde(crate = "rocket::serde")]
pub struct User {
  /// Internal user ID, incremented by 1 for each user created.
  id: u32,
  /// User UUID.
  pub uuid: String,
  /// User's name.
  pub name: String,
  /// User's biography for their profile.
  pub bio: String,
  /// User's email address.
  pub email: String,
  /// User's encrypted password.
  pub password: String,
  /// The last time the user has logged in, as a unix timestamp.
  pub last_login: u32,
  /// The user's join date, as a unix timestamp.
  pub date_joined: u32,
  /// If the user is associated with a store, the store's UUID.
  pub store_uuid: Option<String>,
  /// Whether the user is a paying subscriber. Defaults to `false`.
  pub is_subscribed: bool,
}
impl User {
  fn get_from_row<'a, T: sqlx::Decode<'a, Sqlite> + sqlx::Type<Sqlite>>(row: &'a sqlx::sqlite::SqliteRow, column: &str) -> T {
    row.try_get::<T, _>(column).unwrap()
  }

  /// Creates a new user.
  pub async fn new(db: &mut SqliteConnection, uuid: String) -> Option<Self> {
    sqlx
      ::query("SELECT * FROM users WHERE uuid = $1")
      .bind(&uuid)
      .fetch_one(db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| {
        let id: u32 = Self::get_from_row(&row, "id");
        let name: String = Self::get_from_row(&row, "name");
        let bio: String = Self::get_from_row(&row, "bio");
        let email: String = Self::get_from_row(&row, "email");
        let password: String = Self::get_from_row(&row, "password");
        let last_login: u32 = Self::get_from_row(&row, "last_login");
        let date_joined: u32 = Self::get_from_row(&row, "date_joined");
        let store_uuid: Option<String> = Self::get_from_row(&row, "store_uuid");
        let is_subscribed: u8 = Self::get_from_row(&row, "is_subscribed");
        Ok(Self {
          id,
          uuid,
          name,
          bio,
          email,
          password,
          last_login,
          date_joined,
          store_uuid,
          is_subscribed: is_subscribed == 1,
        })
      })
      .ok()
  }

  pub fn serialize(&self) -> SerializedUser {
    SerializedUser {
      uuid: self.uuid.clone(),
      name: self.name.clone(),
      bio: self.bio.clone(),
      email: self.email.clone(),
      last_login: self.last_login,
      date_joined: self.date_joined,
      store_uuid: self.store_uuid.clone(),
      is_subscribed: self.is_subscribed,
    }
  }

  /// Gets the user's allergies.
  ///
  /// Returns `Vec<(id, allergy)>`
  pub async fn get_allergies(&self, db: &mut SqliteConnection) -> Vec<(u32, String)> {
    sqlx
      ::query("SELECT * FROM user_allergies WHERE user_uuid = $1 LIMIT 100")
      .bind(&self.uuid)
      .fetch_all(db).await
      .and_then(|rows: Vec<sqlx::sqlite::SqliteRow>| {
        let allergies: Vec<(u32, String)> = rows
          .into_iter()
          .map(|row: sqlx::sqlite::SqliteRow| {
            let id: u32 = Self::get_from_row(&row, "id");
            let allergy: String = Self::get_from_row(&row, "allergy");
            (id, allergy)
          })
          .collect();
        Ok(allergies)
      })
      .unwrap()
  }

  /// Gets the user's reviews left on other stores.
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
