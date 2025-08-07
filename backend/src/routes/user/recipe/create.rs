use crate::{ guards::auth::AuthenticatedUser, models::users::recipe::IngredientUnit, utils::functions::get_unix_seconds };
use rocket::serde::{ json::{ Json, to_string }, Deserialize };
use rocket_db_pools::{ sqlx, Connection };
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct RecipeInput {
  /// The recipe's name.
  pub name: String,
  /// Array of the names of the recipe's ingredients.
  ///
  /// `(name, amount, unit)`
  ///
  /// `amount` can be up to 2 decimal places.
  ///
  /// Options for `unit` are listed in `IngredientUnit` (`Gram`, `Liter`, etc).
  pub ingredients: Vec<(String, f32, IngredientUnit)>,
  /// User-generated instructions for the recipe.
  pub instructions: Option<String>,
  /// A user-generated category/tag for the recipe.
  pub category: Option<String>,
  /// A JSON blob of the recipe's display image.
  pub image: Option<String>,
}

/// # Create a Recipe
/// **Route**: /user/recipe/create
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   name: string;
///   ingredients: [name: string, amount: number, unit: string][];
///   instructions?: string;
///   category?: string;
///   image?: string;
/// }
/// ```
///
/// **Output**: `string` - The recipe's UUID
#[post("/create", data = "<data>")]
pub async fn create(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<RecipeInput>) -> String {
  let uuid: String = uuid::Uuid::new_v4().to_string();

  let ingredients: Vec<(String, f32, IngredientUnit)> = data.0.ingredients
    .into_iter()
    .map(|ingredient: (String, f32, IngredientUnit)| {
      let amount: f32 = ingredient.1 * 100.0;
      let amount: f32 = amount.trunc() / 100.0;
      (ingredient.0, amount, ingredient.2)
    })
    .collect();
  let ingredients: String = to_string(&ingredients).unwrap();

  sqlx
    ::query("INSERT INTO recipes (uuid, user_uuid, created_at, last_updated, name, ingredients, instructions, category, image) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)")
    .bind(&uuid)
    .bind(user.0.uuid)
    .bind(get_unix_seconds() as u32)
    .bind(data.0.name)
    .bind(ingredients)
    .bind(data.0.instructions)
    .bind(data.0.category)
    .bind(data.0.image)
    .execute(&mut **db).await
    .unwrap();

  uuid
}
