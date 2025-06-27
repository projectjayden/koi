#[macro_use]
extern crate rocket;

use rocket_db_pools::Database;

mod catchers;
mod guards;
mod models;
mod routes;
mod utils;

#[get("/")]
fn index() -> &'static str {
  "ok"
}

#[launch]
fn rocket() -> _ {
  dotenvy::dotenv().ok();
  rocket
    ::build()
    .attach(utils::db::Db::init())
    .mount("/", routes![index])
    .mount("/auth", routes![routes::auth::init, routes::auth::signup, routes::auth::login, routes::auth::logout])
    .register("/", catchers![catchers::bad_request, catchers::unauthorized, catchers::not_found, catchers::internal_server_error])
}
