use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::Connection;
use rocket_db_pools::sqlx;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct CreateData {
  name: String,
  /// Street address of the store, for users.
  street_address: String,
  /// Latitude and logitude of the store.
  ///
  /// ! When creating the store, the user should be at the store's location.
  geolocation: String,
  /// 10-digit contact phone number, for users.
  ///
  /// Do not include country code. It assumes a +1 prefix.
  ///
  /// Do not include hyphens.
  phone: Option<String>,
  /// Contact email, for users.
  email: Option<String>,
  /// 7x2 array representing open hours.
  ///
  /// The first tuple is Monday, then Tuesday, etc, ending on Sunday.
  ///
  /// The first value of each tuple is the open time, the second is the closing time.
  ///
  /// Time should be in 24-hour format, with colon.
  open_hours: Option<[(String, String); 7]>,
}

/// # Create Store
/// **Route**: /store/create
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   name: string;
///   address: string;
///   phone?: string;
///   email?: string;
///   open_hours?: [[string, string], [string, string], ...x5];
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
/// - 400 (invalid phone number)
#[post("/create", format = "json", data = "<data>")]
pub async fn create(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<CreateData>) -> Status {
  // if data.0.phone.is_some() && data.0.phone.unwrap().len() != 10 {
  //   return Status::BadRequest;
  // }

  // // TODO: subscription
  // // todo: watch https://discord.com/quests/1392248617129082991
  // sqlx
  //   ::query("UPDATE users SET is_subscribed = $1 WHERE uuid = $2")
  //   .bind(data.0.new_status as u8)
  //   .bind(&user.0.uuid)
  //   .execute(&mut **db).await
  //   .unwrap();
  Status::Ok
}
