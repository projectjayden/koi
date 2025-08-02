use rocket::{ http::Status, serde::{ json::{ Json, to_string }, Deserialize } };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::{ sqlx, Connection };
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct UpdateProfileInput {
  /// The user's name.
  pub name: String,
  /// The user's bio.
  pub bio: Option<String>,
  /// Array of the names of the user's allergies.
  pub allergies: Option<Vec<String>>,
}

/// # Update Profile
/// **Route**: /user/update
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   name: string;
///   bio?: string;
///   allergies?: string[];
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
#[post("/update", format = "json", data = "<data>")]
pub async fn update_profile(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<UpdateProfileInput>) -> Status {
  sqlx
    ::query("UPDATE users SET name = $1, bio = $2, allergies = $3 WHERE uuid = $4")
    .bind(data.0.name)
    .bind(data.0.bio)
    .bind(to_string(&data.0.allergies.unwrap_or(vec![])).unwrap())
    .bind(user.0.uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
