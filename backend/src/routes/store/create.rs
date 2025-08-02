use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::{ sqlx::Sqlite, Connection };
use crate::guards::auth::AuthenticatedUser;
use rocket_db_pools::sqlx;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde")]
pub struct CreateData {
  /// Name of the store.
  name: String,
  /// Description of the store.
  description: Option<String>,
  /// GPS coordinate of the store.
  ///
  /// Format: `<latitude>, <longitude>`
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
  /// Time should be in 24-hour format, with colons and leading 0s.
  /// 
  /// If the store is closed all day, use `("00:00", "23:59")`
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
///   description?: string;
///   geolocation: `${number}, ${number}`;
///   phone?: string;
///   email?: string;
///   open_hours?: [[string, string], [string, string], ...x5];
/// }
/// ```
///
/// **Output**:
/// - 200 (success)
/// - 400 (invalid phone number, email, or open hours)
/// - 500 (invalid geolocation)
#[post("/create", format = "json", data = "<data>")]
pub async fn create(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<CreateData>) -> Status {
  if data.0.phone.is_some() && data.0.phone.clone().unwrap().len() != 10 {
    return Status::BadRequest;
  }

  if data.0.email.is_some() && !data.0.email.clone().unwrap().contains('@') {
    return Status::BadRequest;
  }

  let open_hours_entered: bool = data.0.open_hours.is_some();
  if open_hours_entered {
    for (_, (open, close)) in data.0.open_hours.clone().unwrap().iter().enumerate() {
      if open.len() != 5 || close.len() != 5 {
        // not 24-hour format
        return Status::BadRequest;
      }
    }
  }

  let uuid: String = uuid::Uuid::new_v4().to_string();

  // ? parsing to f32 adds random precision when inserting to db ??
  let (latitude, longitude) = match data.0.geolocation.split(", ").collect::<Vec<&str>>().as_slice() {
    [lat, long] => (*lat, *long),
    _ => {
      return Status::InternalServerError;
    }
  };

  let query_string: &'static str = if open_hours_entered {
    "INSERT INTO stores (uuid, name, description, latitude, longitude, phone, email, open_mon, close_mon, open_tue, close_tue, open_wed, close_wed, open_thu, close_thu, open_fri, close_fri, open_sat, close_sat, open_sun, close_sun) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21)"
  } else {
    "INSERT INTO stores (uuid, name, description, latitude, longitude, phone, email) VALUES ($1, $2, $3, $4, $5, $6, $7)"
  };

  let mut insert_query: sqlx::query::Query<'_, Sqlite, _> = sqlx
    ::query(query_string)
    .bind(&uuid)
    .bind(data.0.name)
    .bind(data.0.description)
    .bind(latitude)
    .bind(longitude)
    .bind(data.0.phone)
    .bind(data.0.email);

  let open_hours: [(String, String); 7] = data.0.open_hours.clone().unwrap_or_default();
  if open_hours_entered {
    for (_, (open, close)) in open_hours.iter().enumerate() {
      insert_query = insert_query.bind(open).bind(close);
    }
  }

  insert_query.execute(&mut **db).await.unwrap();

  sqlx::query("UPDATE users SET store_uuid = $1 WHERE uuid = $2").bind(uuid).bind(&user.0.uuid).execute(&mut **db).await.unwrap();
  Status::Ok
}
