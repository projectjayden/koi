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
    .mount("/auth", routes![routes::auth::Init, routes::auth::Signup, routes::auth::Login, routes::auth::Logout, routes::auth::ChangePassword, routes::auth::DeleteAccount])
    .mount("/user", routes![routes::user::Lookup])
    .mount("/user/account", routes![routes::user::account::ManageSubscription, routes::user::account::ManageDeals])
    .register("/", catchers![catchers::bad_request, catchers::unauthorized, catchers::not_found, catchers::internal_server_error])
}
