use crate::{ guards::auth::AuthenticatedUser, models::users::Recipe, models::users::recipe::IngredientUnit, utils::functions::get_unix_seconds };
use rocket::{ http::Status, serde::{ json::{ Json, to_string }, Deserialize } };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct RecipeInput {
  /// The recipe's name.
  pub name: Option<String>,
  /// Array of the names of the recipe's ingredients.
  ///
  /// `(name, amount, unit)`
  ///
  /// `amount` can be up to 2 decimal places.
  ///
  /// Options for `unit` are listed in `IngredientUnit` (`Gram`, `Liter`, etc).
  pub ingredients: Option<Vec<(String, f32, IngredientUnit)>>,
  /// User-generated instructions for the recipe.
  pub instructions: Option<String>,
  /// A user-generated category/tag for the recipe.
  pub category: Option<String>,
  /// A JSON blob of the recipe's display image.
  pub image: Option<String>,
}

/// # Edit a Recipe
/// **Route**: /user/recipe/edit/<uuid>
///
/// **Request method**: PATCH
///
/// **Input**: Same as /user/recipe/create but everything is optional
///
/// **Output**:
/// - 200 (success)
/// - 401 (recipe not owned)
/// - 404 (recipe not found)
#[patch("/edit/<uuid>", data = "<data>")]
pub async fn edit(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str, data: Json<RecipeInput>) -> Status {
  let author_uuid: Option<String> = sqlx
    ::query("SELECT user_uuid FROM recipes WHERE uuid = $1")
    .bind(&uuid)
    .fetch_one(&mut **db).await
    .and_then(|row: SqliteRow| Ok(row.try_get::<String, _>("user_uuid").unwrap()))
    .ok();
  if let None = author_uuid {
    return Status::NotFound;
  }

  let author_uuid: String = author_uuid.unwrap();
  if author_uuid != user.0.uuid {
    return Status::Unauthorized;
  }

  let existing_recipe: Option<Recipe> = Recipe::from_uuid(&mut **db, uuid.to_string()).await;
  if existing_recipe.is_none() {
    return Status::NotFound;
  }
  let existing_recipe: Recipe = existing_recipe.unwrap();

  let name: &String = data.0.name.as_ref().unwrap_or(&existing_recipe.name);
  let instructions: Option<String> = data.0.instructions.or(existing_recipe.instructions);
  let category: Option<String> = data.0.category.or(existing_recipe.category);
  let image: Option<String> = data.0.image.or(existing_recipe.image);

  let ingredients: Vec<(String, f32, IngredientUnit)> = if data.0.ingredients.is_some() {
    data.0.ingredients
      .unwrap()
      .into_iter()
      .map(|ingredient: (String, f32, IngredientUnit)| {
        let amount: f32 = ingredient.1 * 100.0;
        let amount: f32 = amount.trunc() / 100.0;
        (ingredient.0, amount, ingredient.2)
      })
      .collect()
  } else {
    existing_recipe.ingredients
  };
  let ingredients: String = to_string(&ingredients).unwrap();

  sqlx
    ::query("UPDATE recipes SET name = $1, ingredients = $2, instructions = $3, category = $4, image = $5 WHERE uuid = $6 AND user_uuid = $7")
    .bind(get_unix_seconds() as u32)
    .bind(name)
    .bind(ingredients)
    .bind(instructions)
    .bind(category)
    .bind(image)
    .bind(uuid)
    .bind(user.0.uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
