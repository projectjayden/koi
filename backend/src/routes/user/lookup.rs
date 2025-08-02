use crate::{ guards::auth::AuthenticatedUser, models::users::{ user::MiniUser, SerializedRecipe } };
use rocket::{ http::Status, serde::json::Json };
use rocket_db_pools::{sqlx, Connection};
use crate::utils::db::Db;

/// # User Lookup
/// **DO NOT** use this to look up the user's own profile.
/// 
/// **Route**: /user/<uuid>
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// ```ts
/// [
///   { /* User */
///     uuid: string;
///     name: string;
///     bio: string | null;
///     is_subscribed: boolean;
///     followers: number;
///     following: number;
///   },
///   number, // total recipes
///   { /* 20 recipes */
///     uuid: string;
///     user_uuid: string;
///     name: string;
///     ingredients: [name: string, amount: number, unit: string][];
///     category: string | null;
///     image: string | null;
///   }[]
/// ]
/// ```
/// - 404 (user not found)
#[get("/<uuid>", format = "json")]
pub async fn lookup(mut db: Connection<Db>, _user: AuthenticatedUser, uuid: &str) -> Result<Json<(MiniUser, usize, Vec<SerializedRecipe>)>, Status> {
  let user_exists: bool = sqlx::query("SELECT uuid FROM users WHERE uuid = $1")
  .bind(&uuid)
  .fetch_one(&mut **db)
  .await
  .is_ok();
  
  if !user_exists {
    return Err(Status::NotFound);
  }
  
  let user: MiniUser = MiniUser::new(&mut db, uuid.to_string()).await;
  let (total_recipes, recipes) = user.get_recipes(&mut db, 20, 0).await;

  let mut serialized_recipes: Vec<SerializedRecipe> = vec![];
  for recipe in recipes {
    serialized_recipes.push(recipe.serialize(&mut **db).await);
  }

  Ok(Json((user, total_recipes, serialized_recipes)))
}
