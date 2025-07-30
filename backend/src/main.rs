#[macro_use]
extern crate rocket;

use rocket_db_pools::Database;
use rocket::http::Status;

// mod machine_learning;
mod catchers;
mod guards;
mod models;
mod routes;
mod utils;
// mod scripts;

#[get("/")]
fn index() -> Status {
  // scripts::generate_keys::main();
  Status::NotFound
}

#[launch]
fn rocket() -> _ {
  dotenvy::dotenv().ok();
  rocket
    ::build()
    .attach(utils::db::Db::init())
    .mount("/", routes![index])
    .mount("/auth", routes![routes::auth::Init, routes::auth::Signup, routes::auth::Login, routes::auth::Logout, routes::auth::ChangePassword, routes::auth::DeleteAccount])
    .mount("/user", routes![routes::user::user_info, routes::user::Lookup])
    .mount("/user/account", routes![routes::user::account::ManageSubscription, routes::user::account::ManageDeals, routes::user::account::AddAllergies, routes::user::account::RemoveAllergies])
    .mount("/store", routes![routes::store::store_info, routes::store::Create, routes::store::Lookup])
    .register("/", catchers![catchers::bad_request, catchers::unauthorized, catchers::forbidden, catchers::not_found, catchers::internal_server_error])
}
