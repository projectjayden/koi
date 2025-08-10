use crate::{ guards::auth::AuthenticatedUser, models::users::{ recipe::IngredientUnit, Recipe, SerializedRecipe } };
use rocket::{ http::Status, serde::{ json::{ from_str, Json }, Deserialize } };
use rocket_db_pools::{ sqlx::{ self, sqlite::SqliteRow, Row }, Connection };
use crate::utils::{ db::Db, functions::get_from_row };

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct RecipeInput {
  /// Number of recipes to get.
  ///
  /// Defaults to `20`.
  pub limit: Option<u32>,
  /// Offset of recipes.
  ///
  /// Defaults to `0`.
  pub offset: Option<u32>,
}

/// # Get All Recipes
/// Gets recipes from anyone except the current user.
///
/// **Route**: /user/get-all-recipes
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   limit?: number;
///   offset?: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// {
///   uuid: number;
///   userUuid: number;
///   createdAt: number;
///   lastUpdated: number;
///   name: string;
///   ingredients: [name: string, amount: number, unit: string][];
///   category: string | null;
///   image: string | null;
///   isAiGenerated: boolean;
/// }[];
/// ```
#[post("/get-all-recipes", data = "<data>")]
pub async fn get_all_recipes(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<RecipeInput>) -> Result<Json<Vec<SerializedRecipe>>, Status> {
  let limit: u32 = data.0.limit.unwrap_or(20);
  let offset: u32 = data.0.offset.unwrap_or(0);

  let recipes: Vec<Recipe> = sqlx
    ::query("SELECT * FROM recipes WHERE user_uuid != $1 LIMIT $2 OFFSET $3")
    .bind(&user.0.uuid)
    .bind(limit)
    .bind(offset)
    .fetch_all(&mut **db).await
    .and_then(|rows: Vec<SqliteRow>| {
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
    })
    .unwrap();

  let mut serialized_recipes: Vec<SerializedRecipe> = vec![];
  for recipe in recipes {
    serialized_recipes.push(recipe.serialize(&mut **db).await);
  }

  Ok(Json(serialized_recipes))
}
