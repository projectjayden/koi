use crate::guards::{ auth::AuthenticatedUser, store_auth::AuthenticatedStore };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::{ sqlx, Connection };
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct UpdateInfoInput {
  /// Name of the store.
  name: Option<String>,
  /// Description of the store.
  description: Option<String>,
  /// GPS coordinate of the store.
  ///
  /// Format: `<latitude>, <longitude>`
  geolocation: Option<String>,
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
  /// Time should be in 24-hour format, with colons and leading 0s.
  ///
  /// If the store is open all day, use `("00:00", "23:59")`.
  ///
  /// If the store is closed all day, use `("00:00", "00:00")`.
  open_hours: Option<[(String, String); 7]>,
}

/// # Update Info
/// **Route**: /store/update
///
/// **Request method**: PATCH
///
/// **Input**: Same as /store/create but everything is optional
///
/// **Output**:
/// - 200 (success)
#[patch("/update", data = "<data>")]
pub async fn update_info(mut db: Connection<Db>, _user: AuthenticatedUser, store: AuthenticatedStore, data: Json<UpdateInfoInput>) -> Status {
  let name: &String = data.0.name.as_ref().unwrap_or(&store.0.name);
  let description: Option<String> = data.0.description.or(store.0.description);
  let phone: Option<String> = data.0.phone.or(store.0.phone);
  let email: Option<String> = data.0.email.or(store.0.email);
  let open_hours: Option<[(String, String); 7]> = data.0.open_hours.or(store.0.open_hours);

  let (latitude, longitude) = match data.0.geolocation {
    Some(geolocation) => {
      let geolocation: Vec<f32> = geolocation
        .split(',')
        .map(|s| s.parse().unwrap())
        .collect();
      (geolocation[0], geolocation[1])
    }
    None => (store.0.latitude, store.0.longitude),
  };

  let query_string: &'static str = if open_hours.is_some() {
    "UPDATE stores SET name = $1, description = $2, latitude = $3, longitude = $4, phone = $5, email = $6, open_mon = $8, close_mon = $9, open_tue = $10, close_tue = $11, open_wed = $12, close_wed = $13, open_thu = $14, close_thu = $15, open_fri = $16, close_fri = $17, open_sat = $18, close_sat = $19, open_sun = $20, close_sun = $21 WHERE uuid = $7"
  } else {
    "UPDATE stores SET name = $1, description = $2, latitude = $3, longitude = $4, phone = $5, email = $6 WHERE uuid = $7"
  };

  let mut query: sqlx::query::Query<'_, _, _> = sqlx::query(query_string).bind(name).bind(description).bind(latitude).bind(longitude).bind(phone).bind(email).bind(store.0.uuid);

  if open_hours.is_some() {
    for day in open_hours.unwrap() {
      query = query.bind(day.0).bind(day.1);
    }
  }

  query.execute(&mut **db).await.unwrap();

  Status::Ok
}
