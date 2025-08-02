use rocket_db_pools::sqlx::{ self, Row, Sqlite, SqliteConnection };
use rocket::serde::{ Deserialize, Serialize, json::from_str };

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct SerializedRecipe {
  /// Recipe UUID.
  pub uuid: String,
  /// User UUID of the author of the recipe.
  pub user_uuid: String,
  /// Name of the recipe.
  pub name: String,
  /// Ingredients of the recipe.
  /// 
  /// `(name, amount, unit)`
  pub ingredients: Vec<(String, f32, String)>,
  /// Instructions of the recipe.
  pub instructions: Option<String>,
  /// User-created category of the recipe.
  pub category: Option<String>,
  /// JSON blob of the recipe's image.
  pub image: Option<String>,
  /// Number of likes the recipe has.
  pub likes: u32
}

#[derive(Deserialize, Serialize)]
#[serde(crate = "rocket::serde")]
pub struct Recipe {
  /// Internal recipe ID, incremented by 1 for each recipe created.
  id: u32,
  /// Recipe UUID.
  pub uuid: String,
  /// User UUID of the author of the recipe.
  pub user_uuid: String,
  /// Name of the recipe.
  pub name: String,
  /// Ingredients of the recipe.
  /// 
  /// `(name, amount, unit)`
  pub ingredients: Vec<(String, f32, String)>,
  /// Instructions of the recipe.
  pub instructions: Option<String>,
  /// User-created category of the recipe.
  pub category: Option<String>,
  /// JSON blob of the recipe's image.
  pub image: Option<String>
}
impl Recipe {
  fn get_from_row<'a, T: sqlx::Decode<'a, Sqlite> + sqlx::Type<Sqlite>>(row: &'a sqlx::sqlite::SqliteRow, column: &str) -> T {
    row.try_get::<T, _>(column).unwrap()
  }

  pub async fn new(db: &mut SqliteConnection, uuid: String) -> Option<Self> {
    sqlx
      ::query("SELECT * FROM recipes WHERE uuid = $1")
      .bind(uuid)
      .fetch_one(db).await
      .and_then(|row: sqlx::sqlite::SqliteRow| {
        let id: u32 = Self::get_from_row(&row, "id");
        let uuid: String = Self::get_from_row(&row, "uuid");
        let user_uuid: String = Self::get_from_row(&row, "user_uuid");
        let name: String = Self::get_from_row(&row, "name");
        let ingredients: String = Self::get_from_row(&row, "ingredients");
        let ingredients: Vec<(String, f32, String)> = from_str(&ingredients).unwrap();
        let instructions: Option<String> = Self::get_from_row(&row, "instructions");
        let category: Option<String> = Self::get_from_row(&row, "category");
        let image: Option<String> = Self::get_from_row(&row, "image");
        Ok(Self {
          id,
          uuid,
          user_uuid,
          name,
          ingredients,
          instructions,
          category,
          image
        })
      })
      .ok()
  }

  pub async fn serialize(&self, db: &mut SqliteConnection) -> SerializedRecipe {
    let likes: (u32,) = sqlx::query_as("SELECT COUNT(*) FROM recipes_liked WHERE recipe_uuid = $1").bind(&self.uuid).fetch_one(&mut *db).await.unwrap();

    SerializedRecipe {
      uuid: self.uuid.clone(),
      user_uuid: self.user_uuid.clone(),
      name: self.name.clone(),
      ingredients: self.ingredients.clone(),
      instructions: self.instructions.clone(),
      category: self.category.clone(),
      image: self.image.clone(),
      likes: likes.0
    }
  }

  pub fn from_data(id: u32, uuid: String, user_uuid: String, name: String, ingredients: Vec<(String, f32, String)>, instructions: Option<String>, category: Option<String>, image: Option<String>) -> Self {
    Self {
      id,
      uuid,
      user_uuid,
      name,
      ingredients,
      instructions,
      category,
      image
    }
  }
}
