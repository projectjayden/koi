use crate::{ guards::auth::AuthenticatedUser, routes::user::recipe::create::{ RecipeInput, IngredientUnit } };
use rocket_db_pools::{ sqlx::{ self, Row, sqlite::SqliteRow }, Connection };
use rocket::{ http::Status, serde::json::{ Json, to_string } };
use crate::utils::db::Db;

/// # Edit a Recipe
/// **Route**: /user/recipe/edit/<uuid>
///
/// **Request method**: POST
///
/// **Input**: Same as /user/recipe/create
///
/// **Output**:
/// - 200 (success)
/// - 401 (recipe not owned)
#[post("/edit/<uuid>", format = "json", data = "<data>")]
pub async fn edit(mut db: Connection<Db>, user: AuthenticatedUser, uuid: &str, data: Json<RecipeInput>) -> Status {
  let author_uuid: String = sqlx
    ::query("SELECT user_uuid FROM recipes WHERE uuid = $1")
    .bind(&uuid)
    .fetch_one(&mut **db).await
    .and_then(|row: SqliteRow| Ok(row.try_get::<String, _>("user_uuid").unwrap()))
    .unwrap();
  if author_uuid != user.0.uuid {
    return Status::Unauthorized;
  }

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
    ::query("UPDATE recipes SET name = $1, ingredients = $2, instructions = $3, category = $4, image = $5 WHERE uuid = $6 AND user_uuid = $7")
    .bind(data.0.name)
    .bind(ingredients)
    .bind(data.0.instructions)
    .bind(data.0.category)
    .bind(data.0.image)
    .bind(uuid)
    .bind(user.0.uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
