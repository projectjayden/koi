use crate::{ guards::auth::AuthenticatedUser, models::users::{ user::{ GetRecipesType, MiniUser }, SerializedRecipe } };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct RecipeInput {
  /// UUID of the user to fetch recipes for.
  ///
  /// Defaults to the current user.
  ///
  /// If a UUID is provided, the type of recipes to fetch is ignored and will be set to `0` - authored.
  pub uuid: Option<String>,
  /// Type of data to fetch.
  ///
  /// - 0 = authored recipes
  /// - 1 = liked recipes
  pub r#type: u32,
  /// Number of recipes to get.
  ///
  /// Defaults to `20`.
  pub limit: Option<u32>,
  /// Offset of recipes.
  ///
  /// Defaults to `0`.
  pub offset: Option<u32>,
}

/// # Get Created/Liked Recipes
/// Gets the recipe data for either the user's created or liked recipes.
///
/// **Route**: /user/get-recipes
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   uuid?: string;
///   type: 0 | 1;
///   limit?: number;
///   offset?: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// [
///   number; // total recipes
///   {
///     uuid: number;
///     user_uuid: number;
///     created_at: number;
///     last_updated: number;
///     name: string;
///     ingredients: [name: string, amount: number, unit: string][];
///     category: string | null;
///     image: string | null;
///   }[];
/// ]
/// ```
#[post("/get-recipes", data = "<data>")]
pub async fn get_recipes(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<RecipeInput>) -> Result<Json<(usize, Vec<SerializedRecipe>)>, Status> {
  let limit: u32 = data.0.limit.unwrap_or(20);
  let offset: u32 = data.0.offset.unwrap_or(0);

  let recipe_type: GetRecipesType = if data.0.uuid.is_some() {
    GetRecipesType::Authored
  } else {
    match data.0.r#type {
      0 => GetRecipesType::Authored,
      1 => GetRecipesType::Liked,
      _ => {
        return Err(Status::BadRequest);
      }
    }
  };

  let (total_recipes, recipes) = if data.0.uuid.is_some() {
    MiniUser::new(&mut db, data.0.uuid.unwrap()).await.get_recipes(&mut db, limit, offset).await
  } else {
    user.0.get_recipes(&mut db, recipe_type, limit, offset).await
  };

  let mut serialized_recipes: Vec<SerializedRecipe> = vec![];
  for recipe in recipes {
    serialized_recipes.push(recipe.serialize(&mut **db).await);
  }

  Ok(Json((total_recipes, serialized_recipes)))
}
