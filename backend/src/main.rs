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

#[get("/")]
fn index() -> Status {
  Status::NotFound
}

#[launch]
fn rocket() -> _ {
  dotenvy::dotenv().ok();
  rocket
    ::build()
    .attach(utils::db::Db::init())
    .mount("/", routes![index, routes::AASA])
    .mount("/auth", routes![routes::auth::Init, routes::auth::Signup, routes::auth::Login, routes::auth::ChangePassword, routes::auth::DeleteAccount])
    .mount(
      "/user",
      routes![
        routes::user::GetFame,
        routes::user::GetRecipes,
        routes::user::GetReviews,
        routes::user::GetLists,
        routes::user::Lookup,
        routes::user::Rate,
        routes::user::UpdateProfile,
        routes::user::Follow,
        routes::user::Unfollow,
        routes::user::SearchItems
      ]
    )
    .mount("/user/recipe", routes![routes::user::recipe::LikeRecipe, routes::user::recipe::UnlikeRecipe, routes::user::recipe::Create, routes::user::recipe::Delete, routes::user::recipe::Edit])
    .mount("/user/list", routes![routes::user::list::Create, routes::user::list::Delete, routes::user::list::Edit])
    .mount("/store", routes![routes::store::Create, routes::store::Lookup, routes::store::GetDeals, routes::store::GetItems, routes::store::GetReviews, routes::store::UpdateInfo])
    .mount("/store/item", routes![routes::store::item::Create, routes::store::item::Delete, routes::store::item::Edit])
    .mount("/store/deal", routes![routes::store::deal::Create, routes::store::deal::Delete, routes::store::deal::Edit])
    .register(
      "/",
      catchers![catchers::bad_request, catchers::unauthorized, catchers::forbidden, catchers::not_found, catchers::im_a_teapot, catchers::unprocessable_entity, catchers::internal_server_error]
    )
}
