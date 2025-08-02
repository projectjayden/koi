use rocket_db_pools::sqlx::{ self, Row, SqliteConnection, Error, sqlite::{ Sqlite, SqliteRow } };
use rocket::serde::{ json::from_str, Deserialize, Serialize };
use crate::models::users::{ Review, Recipe };

pub enum GetFollowType {
  Followers,
  Following,
}

pub enum GetRecipesType {
  /// Recipes that the user has created.
  Authored,
  Liked,
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct MiniUser {
  /// User UUID.
  pub uuid: String,
  /// User's name.
  pub name: String,
  /// User's biography for their profile.
  pub bio: Option<String>,
  /// Whether the user is a paying subscriber. Defaults to `false`.
  pub is_subscribed: bool,
  /// Number of followers the user has.
  pub followers: u32,
  /// Number of users the user is following.
  pub following: u32,
}
impl MiniUser {
  pub async fn new(db: &mut SqliteConnection, uuid: String) -> Self {
    let (name, bio, is_subscribed) = sqlx
      ::query("SELECT name, bio, is_subscribed FROM users WHERE uuid = $1")
      .bind(&uuid)
      .fetch_one(&mut *db).await
      .and_then(|row: SqliteRow| {
        let name: String = row.try_get::<String, _>("name").unwrap();
        let bio: Option<String> = row.try_get::<Option<String>, _>("bio").unwrap();
        let is_subscribed: u8 = row.try_get::<u8, _>("is_subscribed").unwrap();
        let is_subscribed: bool = is_subscribed == 1;
        Ok((name, bio, is_subscribed))
      })
      .unwrap();

    let followers: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM followers WHERE followed_uuid = $1").bind(&uuid).fetch_one(&mut *db).await.unwrap();
    let following: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM followers WHERE follower_uuid = $1").bind(&uuid).fetch_one(&mut *db).await.unwrap();

    Self {
      uuid,
      name,
      bio,
      is_subscribed,
      followers: followers.0,
      following: following.0,
    }
  }

  pub async fn get_recipes(&self, db: &mut SqliteConnection, limit: u32, offset: u32) -> (usize, Vec<Recipe>) {
    let total_recipes: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM recipes WHERE user_uuid = $1").bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    let recipes: Vec<Recipe> = sqlx
      ::query("SELECT * FROM recipes WHERE user_uuid = $1 LIMIT $2 OFFSET $3")
      .bind(&self.uuid)
      .bind(limit)
      .bind(offset)
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        rows
          .into_iter()
          .map(|row: SqliteRow| {
            let id: u32 = row.try_get::<u32, _>("id").unwrap();
            let uuid: String = row.try_get::<String, _>("uuid").unwrap();
            let user_uuid: String = row.try_get::<String, _>("user_uuid").unwrap();
            let name: String = row.try_get::<String, _>("name").unwrap();
            let ingredients: String = row.try_get::<String, _>("ingredients").unwrap();
            let ingredients: Vec<(String, f32, String)> = from_str(&ingredients).unwrap();
            let instructions: Option<String> = row.try_get::<Option<String>, _>("instructions").unwrap();
            let category: Option<String> = row.try_get::<Option<String>, _>("category").unwrap();
            let image: Option<String> = row.try_get::<Option<String>, _>("image").unwrap();
            Ok(Recipe::from_data(id, uuid, user_uuid, name, ingredients, instructions, category, image))
          })
          .collect()
      })
      .unwrap();

    (total_recipes.0 as usize, recipes)
  }
}

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
  /// A list of the names of the user's allergies.
  pub allergies: Vec<String>,
  /// Number of followers the user has.
  pub followers: u32,
  /// Number of users the user is following.
  pub following: u32,
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
  /// A list of the names of the user's allergies.
  pub allergies: Vec<String>,
}
impl User {
  fn get_from_row<'a, T: sqlx::Decode<'a, Sqlite> + sqlx::Type<Sqlite>>(row: &'a SqliteRow, column: &str) -> T {
    row.try_get::<T, _>(column).unwrap()
  }

  /// Creates a new user.
  pub async fn new(db: &mut SqliteConnection, uuid: String) -> Option<Self> {
    sqlx
      ::query("SELECT * FROM users WHERE uuid = $1")
      .bind(&uuid)
      .fetch_one(db).await
      .and_then(|row: SqliteRow| {
        let id: u32 = Self::get_from_row(&row, "id");
        let name: String = Self::get_from_row(&row, "name");
        let bio: String = Self::get_from_row(&row, "bio");
        let email: String = Self::get_from_row(&row, "email");
        let password: String = Self::get_from_row(&row, "password");
        let last_login: u32 = Self::get_from_row(&row, "last_login");
        let date_joined: u32 = Self::get_from_row(&row, "date_joined");
        let store_uuid: Option<String> = Self::get_from_row(&row, "store_uuid");
        let is_subscribed: u8 = Self::get_from_row(&row, "is_subscribed");
        let allergies: Option<String> = Self::get_from_row(&row, "allergies");
        let allergies: Vec<String> = from_str(&allergies.unwrap_or("[]".to_string())).unwrap();
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
          allergies,
        })
      })
      .ok()
  }

  pub async fn serialize(&self, db: &mut SqliteConnection) -> SerializedUser {
    let followers: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM followers WHERE followed_uuid = $1").bind(&self.uuid).fetch_one(&mut *db).await.unwrap();
    let following: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM followers WHERE follower_uuid = $1").bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    SerializedUser {
      uuid: self.uuid.clone(),
      name: self.name.clone(),
      bio: self.bio.clone(),
      email: self.email.clone(),
      last_login: self.last_login,
      date_joined: self.date_joined,
      store_uuid: self.store_uuid.clone(),
      is_subscribed: self.is_subscribed,
      allergies: self.allergies.clone(),
      followers: followers.0,
      following: following.0,
    }
  }

  /// Gets the user's reviews left on other stores.
  ///
  /// Returns `(total_reviews, reviews)``
  pub async fn get_reviews(&self, db: &mut SqliteConnection, limit: u32, offset: u32) -> (usize, Vec<Review>) {
    let total_reviews: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM store_reviews WHERE user_uuid = $1").bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    let reviews: Vec<Review> = sqlx
      ::query("SELECT * FROM store_reviews WHERE user_uuid = $1 LIMIT $2 OFFSET $3")
      .bind(&self.uuid)
      .bind(limit)
      .bind(offset)
      .fetch_all(db).await
      .and_then(|rows: Vec<SqliteRow>| {
        Ok::<Result<Vec<Review>, Error>, Error>(
          rows
            .into_iter()
            .map(|row: SqliteRow| {
              let id: u32 = Self::get_from_row(&row, "id");
              let user_uuid: String = Self::get_from_row(&row, "user_uuid");
              let store_uuid: String = Self::get_from_row(&row, "store_uuid");
              let rating: f32 = Self::get_from_row(&row, "rating");
              let description: String = Self::get_from_row(&row, "description");

              Ok(Review::new(id, user_uuid, store_uuid, rating, description))
            })
            .collect()
        ).unwrap()
      })
      .unwrap();

    (total_reviews.0 as usize, reviews)
  }

  /// Gets a small array of the user's followers or following and some information about them.
  ///
  /// Returns `(total_followers/following, followers/following)``
  pub async fn get_fame(&self, db: &mut SqliteConnection, follow_type: GetFollowType, limit: u32, offset: u32) -> (usize, Vec<MiniUser>) {
    let type_to_get_from: &'static str = match follow_type {
      GetFollowType::Followers => "followed_uuid",
      GetFollowType::Following => "follower_uuid",
    };
    let type_to_get: &'static str = match follow_type {
      GetFollowType::Followers => "follower_uuid",
      GetFollowType::Following => "followed_uuid",
    };

    let total_followers: (u32,) = sqlx::query_as(format!("SELECT COUNT(*) FROM followers WHERE {} = $1", type_to_get_from).as_str()).bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    let follower_uuids: Vec<String> = sqlx
      ::query(format!("SELECT {} FROM followers WHERE {} = $1 LIMIT $2 OFFSET $3", type_to_get, type_to_get_from).as_str())
      .bind(&self.uuid)
      .bind(limit)
      .bind(offset)
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        Ok::<Result<Vec<String>, Error>, Error>(
          rows
            .into_iter()
            .map(|row: SqliteRow| { Ok(Self::get_from_row(&row, type_to_get)) })
            .collect()
        ).unwrap()
      })
      .unwrap();

    let mut followers: Vec<MiniUser> = vec![];
    for uuid in follower_uuids {
      followers.push(MiniUser::new(db, uuid).await);
    }

    (total_followers.0 as usize, followers)
  }

  /// Gets the user's authored/liked recipes.
  ///
  /// Returns `(total_recipes, recipes)``
  pub async fn get_recipes(&self, db: &mut SqliteConnection, recipe_type: GetRecipesType, limit: u32, offset: u32) -> (usize, Vec<Recipe>) {
    let table_to_get_from: &'static str = match recipe_type {
      GetRecipesType::Authored => "recipes",
      GetRecipesType::Liked => "recipes_liked",
    };

    let total_recipes: (u32,) = sqlx::query_as(format!("SELECT COUNT(*) FROM {} WHERE user_uuid = $1", table_to_get_from).as_str()).bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    let recipes: Vec<Recipe> = match recipe_type {
      GetRecipesType::Authored => self.get_authored_recipes(db, limit, offset).await,
      GetRecipesType::Liked => self.get_liked_recipes(db, limit, offset).await,
    };

    (total_recipes.0 as usize, recipes)
  }

  /// Gets the user's authored recipes.
  async fn get_authored_recipes(&self, db: &mut SqliteConnection, limit: u32, offset: u32) -> Vec<Recipe> {
    sqlx
      ::query("SELECT * FROM recipes WHERE user_uuid = $1 LIMIT $2 OFFSET $3")
      .bind(&self.uuid)
      .bind(limit)
      .bind(offset)
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        Ok::<Result<Vec<Recipe>, Error>, Error>(
          rows
            .into_iter()
            .map(|row: SqliteRow| {
              let id: u32 = Self::get_from_row(&row, "id");
              let uuid: String = Self::get_from_row(&row, "uuid");
              let user_uuid: String = Self::get_from_row(&row, "user_uuid");
              let name: String = Self::get_from_row(&row, "name");
              let ingredients: String = Self::get_from_row(&row, "ingredients");
              let ingredients: Vec<(String, f32, String)> = from_str(&ingredients).unwrap();
              let instructions: Option<String> = Self::get_from_row(&row, "instructions");
              let category: Option<String> = Self::get_from_row(&row, "category");
              let image: Option<String> = Self::get_from_row(&row, "image");

              Ok(Recipe::from_data(id, uuid, user_uuid, name, ingredients, instructions, category, image))
            })
            .collect()
        ).unwrap()
      })
      .unwrap()
  }

  /// Gets the user's liked recipes.
  async fn get_liked_recipes(&self, db: &mut SqliteConnection, limit: u32, offset: u32) -> Vec<Recipe> {
    let recipe_uuids: Vec<String> = sqlx
      ::query("SELECT recipe_uuid FROM recipes_liked WHERE user_uuid = $1 LIMIT $2 OFFSET $3")
      .bind(&self.uuid)
      .bind(limit)
      .bind(offset)
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        Ok::<Result<Vec<String>, Error>, Error>(
          rows
            .into_iter()
            .map(|row: SqliteRow| { Ok(Self::get_from_row(&row, "recipe_uuid")) })
            .collect()
        ).unwrap()
      })
      .unwrap();

    sqlx
      ::query("SELECT * FROM recipes WHERE uuid IN ($1)")
      .bind(&recipe_uuids.join(", "))
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        Ok::<Result<Vec<Recipe>, Error>, Error>(
          rows
            .into_iter()
            .map(|row: SqliteRow| {
              let id: u32 = Self::get_from_row(&row, "id");
              let uuid: String = Self::get_from_row(&row, "uuid");
              let user_uuid: String = Self::get_from_row(&row, "user_uuid");
              let name: String = Self::get_from_row(&row, "name");
              let ingredients: String = Self::get_from_row(&row, "ingredients");
              let ingredients: Vec<(String, f32, String)> = from_str(&ingredients).unwrap();
              let instructions: Option<String> = Self::get_from_row(&row, "instructions");
              let category: Option<String> = Self::get_from_row(&row, "category");
              let image: Option<String> = Self::get_from_row(&row, "image");

              Ok(Recipe::from_data(id, uuid, user_uuid, name, ingredients, instructions, category, image))
            })
            .collect()
        ).unwrap()
      })
      .unwrap()
  }
}
