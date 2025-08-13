#[macro_use]
extern crate rocket;

use rocket_db_pools::Database;
use rocket::http::Status;
use dashmap::DashMap;
use std::sync::Arc;

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

  let session_store: utils::t5::SessionStore = Arc::new(DashMap::new());

  rocket
    ::build()
    .attach(utils::db::Db::init())
    .manage(session_store)
    .mount("/", routes![index, routes::AASA])
    .mount("/auth", routes![routes::auth::Init, routes::auth::Signup, routes::auth::Login, routes::auth::ChangePassword, routes::auth::DeleteAccount])
    .mount(
      "/user",
      routes![
        routes::user::GetRandomUsers,
        routes::user::UpdateProfile,
        routes::user::GetAllRecipes,
        routes::user::SearchItems,
        routes::user::SearchUsers,
        routes::user::IsFollowing,
        routes::user::GetRecipes,
        routes::user::GetReviews,
        routes::user::Unfollow,
        routes::user::GetLists,
        routes::user::GetFame,
        routes::user::Follow,
        routes::user::Lookup,
        routes::user::Rate
      ]
    )
    .mount("/user/recipe", routes![routes::user::recipe::LikeRecipe, routes::user::recipe::UnlikeRecipe, routes::user::recipe::Create, routes::user::recipe::Delete, routes::user::recipe::Edit])
    .mount("/user/list", routes![routes::user::list::Create, routes::user::list::Delete, routes::user::list::Edit])
    .mount("/user/chat", routes![routes::user::chat::Start, routes::user::chat::End, routes::user::chat::History, routes::user::chat::Message])
    .mount("/store", routes![routes::store::Create, routes::store::Lookup, routes::store::GetDeals, routes::store::GetItems, routes::store::GetReviews, routes::store::UpdateInfo])
    .mount("/store/item", routes![routes::store::item::Create, routes::store::item::Delete, routes::store::item::Edit])
    .mount("/store/deal", routes![routes::store::deal::Create, routes::store::deal::Delete, routes::store::deal::Edit])
    .register(
      "/",
      catchers![catchers::bad_request, catchers::unauthorized, catchers::forbidden, catchers::not_found, catchers::payload_too_large, catchers::im_a_teapot, catchers::unprocessable_entity, catchers::internal_server_error]
    )
}
