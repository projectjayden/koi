use rocket::{ http::Status, serde::{ json::{ Json, to_string }, Deserialize } };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::{ sqlx, Connection };
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct UpdateProfileInput {
  /// The user's name.
  pub name: Option<String>,
  /// The user's bio.
  pub bio: Option<String>,
  /// The user's email.
  pub email: Option<String>,
  /// Array of the names of the user's allergies.
  pub allergies: Option<Vec<String>>,
  /// Array of the names of the user's preferences.
  pub preferences: Option<Vec<String>>,
}

/// # Update Profile
/// **Route**: /user/update
///
/// **Request method**: PATCH
///
/// **Input**:
/// ```ts
/// {
///   name?: string;
///   bio?: string;
///   email?: string;
///   allergies?: string[];
///   preferences?: string[];
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
#[patch("/update", data = "<data>")]
pub async fn update_profile(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<UpdateProfileInput>) -> Status {
  let name: &String = data.0.name.as_ref().unwrap_or(&user.0.name);
  let bio: Option<String> = data.0.bio.or(user.0.bio);
  let email: &String = data.0.email.as_ref().unwrap_or(&user.0.email);
  let allergies: &Vec<String> = data.0.allergies.as_ref().unwrap_or(&user.0.allergies);
  let preferences: &Vec<String> = data.0.preferences.as_ref().unwrap_or(&user.0.preferences);

  sqlx
    ::query("UPDATE users SET name = $1, bio = $2, email = $3, allergies = $4, preferences = $5 WHERE uuid = $6")
    .bind(name)
    .bind(bio)
    .bind(email)
    .bind(to_string(allergies).unwrap())
    .bind(to_string(preferences).unwrap())
    .bind(user.0.uuid)
    .execute(&mut **db).await
    .unwrap();
  Status::Ok
}
