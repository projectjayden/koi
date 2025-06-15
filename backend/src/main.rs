#[macro_use]
extern crate rocket;

use rocket_db_pools::Database;

mod routes;
mod catchers;
mod utils;

#[get("/")]
fn index() -> &'static str {
  "Hello, world!"
}

#[launch]
fn rocket() -> _ {
  dotenvy::dotenv().ok();
  rocket
    ::build()
    .attach(utils::db::Db::init())
    .mount("/", routes![index])
    .mount("/auth", routes![routes::auth::signup, routes::auth::login, routes::auth::logout])
    .register("/", catchers![catchers::bad_request, catchers::unauthorized, catchers::not_found, catchers::internal_server_error])
}
