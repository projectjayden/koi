use crate::{ models::users::{ list::List, recipe::IngredientUnit, Recipe, Review }, utils::functions::get_from_row };
use rocket_db_pools::sqlx::{ self, Row, query::Query, SqliteConnection, Error, sqlite::SqliteRow };
use rocket::serde::{ json::from_str, Serialize };

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
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
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
        let name: String = get_from_row(&row, "name");
        let bio: Option<String> = get_from_row(&row, "bio");
        let is_subscribed: u8 = get_from_row(&row, "is_subscribed");
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

  pub async fn get_recipes(&self, db: &mut SqliteConnection, get_ai_generated: Option<bool>, limit: u32, offset: u32) -> (usize, Vec<Recipe>) {
    let ai_generated_query: &'static str = match get_ai_generated {
      Some(option) =>
        match option {
          true => " AND is_ai_generated = 1",
          false => " AND is_ai_generated = 0",
        }
      None => "",
    };
    let total_recipes: (u32,) = sqlx::query_as(&format!("SELECT COUNT(*) FROM recipes WHERE user_uuid = $1{}", ai_generated_query)).bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    let recipes: Vec<Recipe> = sqlx
      ::query(&format!("SELECT * FROM recipes WHERE user_uuid = $1{} LIMIT $2 OFFSET $3", ai_generated_query))
      .bind(&self.uuid)
      .bind(limit)
      .bind(offset)
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        rows
          .into_iter()
          .map(|row: SqliteRow| {
            let uuid: String = get_from_row(&row, "uuid");
            let user_uuid: String = get_from_row(&row, "user_uuid");
            let created_at: u32 = get_from_row(&row, "created_at");
            let last_updated: u32 = get_from_row(&row, "last_updated");
            let name: String = get_from_row(&row, "name");
            let ingredients: String = get_from_row(&row, "ingredients");
            let ingredients: Vec<(String, f32, IngredientUnit)> = from_str(&ingredients).unwrap();
            let instructions: Option<String> = get_from_row(&row, "instructions");
            let category: Option<String> = get_from_row(&row, "category");
            let image: Option<String> = get_from_row(&row, "image");
            let is_ai_generated: u8 = get_from_row(&row, "is_ai_generated");
            Ok(Recipe::new(uuid, user_uuid, created_at, last_updated, name, ingredients, instructions, category, image, is_ai_generated))
          })
          .collect()
      })
      .unwrap();

    (total_recipes.0 as usize, recipes)
  }
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct SerializedUser {
  /// User UUID.
  pub uuid: String,
  /// User's name.
  pub name: String,
  /// User's biography for their profile.
  pub bio: Option<String>,
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
  /// A list of tags that the user has set.
  ///
  /// Used for generating lists.
  pub preferences: Vec<String>,
  /// Number of followers the user has.
  pub followers: u32,
  /// Number of users the user is following.
  pub following: u32,
}

pub struct User {
  /// User UUID.
  pub uuid: String,
  /// User's name.
  pub name: String,
  /// User's biography for their profile.
  pub bio: Option<String>,
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
  /// A list of tags that the user has set.
  ///
  /// Used for generating lists.
  pub preferences: Vec<String>,
}
impl User {
  /// Creates a new user.
  pub async fn new(db: &mut SqliteConnection, uuid: String) -> Option<Self> {
    sqlx
      ::query("SELECT * FROM users WHERE uuid = $1")
      .bind(&uuid)
      .fetch_one(db).await
      .and_then(|row: SqliteRow| {
        let name: String = get_from_row(&row, "name");
        let bio: Option<String> = get_from_row(&row, "bio");
        let email: String = get_from_row(&row, "email");
        let password: String = get_from_row(&row, "password");
        let last_login: u32 = get_from_row(&row, "last_login");
        let date_joined: u32 = get_from_row(&row, "date_joined");
        let store_uuid: Option<String> = get_from_row(&row, "store_uuid");
        let is_subscribed: u8 = get_from_row(&row, "is_subscribed");
        let allergies: Option<String> = get_from_row(&row, "allergies");
        let allergies: Vec<String> = from_str(&allergies.unwrap_or("[]".to_string())).unwrap();
        let preferences: Option<String> = get_from_row(&row, "preferences");
        let preferences: Vec<String> = from_str(&preferences.unwrap_or("[]".to_string())).unwrap();
        Ok(Self {
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
          preferences,
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
      preferences: self.preferences.clone(),
      followers: followers.0,
      following: following.0,
    }
  }

  /// Gets the user's reviews left on other stores.
  ///
  /// Returns `(total_reviews, reviews)`
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
              let user_uuid: String = get_from_row(&row, "user_uuid");
              let store_uuid: String = get_from_row(&row, "store_uuid");
              let created_at: u32 = get_from_row(&row, "created_at");
              let rating: f32 = get_from_row(&row, "rating");
              let description: Option<String> = get_from_row(&row, "description");

              Ok(Review::new(user_uuid, store_uuid, created_at, rating, description))
            })
            .collect()
        ).unwrap()
      })
      .unwrap();

    (total_reviews.0 as usize, reviews)
  }

  /// Gets a small array of the user's followers or following and some information about them.
  ///
  /// Returns `(total_followers/following, followers/following)`
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
            .map(|row: SqliteRow| { Ok(get_from_row(&row, type_to_get)) })
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
  /// Returns `(total_recipes, recipes)`
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
              let uuid: String = get_from_row(&row, "uuid");
              let user_uuid: String = get_from_row(&row, "user_uuid");
              let created_at: u32 = get_from_row(&row, "created_at");
              let last_updated: u32 = row.try_get::<u32, _>("last_updated").unwrap();
              let name: String = get_from_row(&row, "name");
              let ingredients: String = get_from_row(&row, "ingredients");
              let ingredients: Vec<(String, f32, IngredientUnit)> = from_str(&ingredients).unwrap();
              let instructions: Option<String> = get_from_row(&row, "instructions");
              let category: Option<String> = get_from_row(&row, "category");
              let image: Option<String> = get_from_row(&row, "image");
              let is_ai_generated: u8 = get_from_row(&row, "is_ai_generated");
              Ok(Recipe::new(uuid, user_uuid, created_at, last_updated, name, ingredients, instructions, category, image, is_ai_generated))
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
            .map(|row: SqliteRow| { Ok(get_from_row(&row, "recipe_uuid")) })
            .collect()
        ).unwrap()
      })
      .unwrap();

    let query_string: Vec<String> = (0..recipe_uuids.len()).map(|i: usize| format!("${}", i + 2)).collect();

    let mut query: Query<'_, _, _> = sqlx::query("SELECT * FROM recipes WHERE uuid IN ($1)").bind(query_string.join(", "));
    for uuid in recipe_uuids.iter() {
      query = query.bind(uuid);
    }

    query
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        Ok::<Result<Vec<Recipe>, Error>, Error>(
          rows
            .into_iter()
            .map(|row: SqliteRow| {
              let uuid: String = get_from_row(&row, "uuid");
              let user_uuid: String = get_from_row(&row, "user_uuid");
              let created_at: u32 = get_from_row(&row, "created_at");
              let last_updated: u32 = row.try_get::<u32, _>("last_updated").unwrap();
              let name: String = get_from_row(&row, "name");
              let ingredients: String = get_from_row(&row, "ingredients");
              let ingredients: Vec<(String, f32, IngredientUnit)> = from_str(&ingredients).unwrap();
              let instructions: Option<String> = get_from_row(&row, "instructions");
              let category: Option<String> = get_from_row(&row, "category");
              let image: Option<String> = get_from_row(&row, "image");
              let is_ai_generated: u8 = get_from_row(&row, "is_ai_generated");
              Ok(Recipe::new(uuid, user_uuid, created_at, last_updated, name, ingredients, instructions, category, image, is_ai_generated))
            })
            .collect()
        ).unwrap()
      })
      .unwrap()
  }

  /// Gets the user's authored/liked recipes.
  ///
  /// Returns `(total_lists, lists)`
  pub async fn get_lists(&self, db: &mut SqliteConnection, limit: u32, offset: u32) -> (usize, Vec<List>) {
    let total_lists: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM lists WHERE user_uuid = $1").bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    let lists: Vec<List> = sqlx
      ::query("SELECT * FROM lists WHERE user_uuid = $1 LIMIT $2 OFFSET $3")
      .bind(&self.uuid)
      .bind(limit)
      .bind(offset)
      .fetch_all(&mut *db).await
      .and_then(|rows: Vec<SqliteRow>| {
        Ok::<Result<Vec<List>, Error>, Error>(
          rows
            .into_iter()
            .map(|row: SqliteRow| {
              let uuid: String = get_from_row(&row, "uuid");
              let user_uuid: String = get_from_row(&row, "user_uuid");
              let created_at: u32 = get_from_row(&row, "created_at");
              let last_updated: u32 = row.try_get::<u32, _>("last_updated").unwrap();
              let items: String = get_from_row(&row, "items");
              let items: Vec<(u8, String)> = from_str(&items).unwrap();

              Ok(List::new(uuid, user_uuid, created_at, last_updated, items))
            })
            .collect()
        ).unwrap()
      })
      .unwrap();

    (total_lists.0 as usize, lists)
  }
}
