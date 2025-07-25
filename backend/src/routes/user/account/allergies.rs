use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::{ sqlx::Sqlite, Connection };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::sqlx;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct AddAllergiesData {
  /// Array of allergy names to add to/remove from the user's allergies list
  allergies: Vec<String>,
}

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct RemoveAllergiesData {
  /// Array of allergy IDs to add to/remove from the user's allergies list
  allergies: Vec<u32>,
}

/// # Add Allergies
/// **Route**: /user/account/allergies/add
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   allergies: string[];
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
#[post("/allergies/add", format = "json", data = "<data>")]
pub async fn add_allergies(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<AddAllergiesData>) -> Status {
  let query: String = data.allergies
    .iter()
    .enumerate()
    .map(|(i, _)| { format!("($1, ${}), ", i + 2) })
    .collect::<String>();
  let query: String = format!("INSERT INTO user_allergies (user_uuid, allergy) VALUES {}", &query[..query.len() - 2]);

  let mut query: sqlx::query::Query<'_, Sqlite, _> = sqlx::query(&query as &str).bind(user.0.uuid);
  for allergy in &data.allergies {
    query = query.bind(allergy);
  }

  query.execute(&mut **db).await.unwrap();
  Status::Ok
}

/// # Remove Allergies
/// **Route**: /user/account/allergies/remove
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   allergies: number[];
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
#[post("/allergies/remove", format = "json", data = "<data>")]
pub async fn remove_allergies(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<RemoveAllergiesData>) -> Status {
  let query: String = data.allergies
    .iter()
    .enumerate()
    .map(|(i, _)| { format!("${}, ", i + 2) })
    .collect::<String>();
  println!("{}", query);
  let query: String = format!("DELETE FROM user_allergies WHERE user_uuid = $1 AND id IN ({})", &query[..query.len() - 2]);
  println!("{}", query);

  let mut query: sqlx::query::Query<'_, Sqlite, _> = sqlx::query(&query as &str).bind(user.0.uuid);
  for id in &data.allergies {
    query = query.bind(id);
  }

  query.execute(&mut **db).await.unwrap();
  Status::Ok
}
