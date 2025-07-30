pub mod account;

pub mod lookup;
// pub mod rate;

pub use lookup::lookup as Lookup;
// pub use rate::rate as Rate;

use crate::{ guards::auth::AuthenticatedUser, models::users::User, utils::db::Db };
use crate::models::users::{ SerializedUserReview, UserReview };
use rocket::{ http::Status, serde::json::Json };
use lookup::{ LookupInput, LookupOutput };
use crate::models::users::SerializedUser;
use rocket_db_pools::Connection;

/// # User Information
/// Same as /user/lookup, but gets the current user's information
///
/// **Route**: /user
///
/// **Request method**: POST
///
/// **Input**:
/// Same as /user/lookup
///
/// **Output**:
/// Same as /user/lookup
#[post("/", format = "json", data = "<data>")]
pub async fn user_info(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<LookupInput>) -> Result<Json<LookupOutput>, Status> {
  // * if get_reviews is true but review_limit or review_offset is missing
  if data.0.get_reviews && (data.0.review_limit.is_none() || data.0.review_offset.is_none()) {
    return Err(Status::BadRequest);
  }

  let user: Option<User> = User::new(&mut **db, user.0.uuid).await;
  if let None = user {
    return Err(Status::NotFound);
  }
  let user: User = user.unwrap();

  let allergies: Option<Vec<(u32, String)>> = if data.0.get_allergies { Some((&user).get_allergies(&mut **db).await) } else { None };

  let review_data: Option<(usize, Vec<UserReview>)> = if data.0.get_reviews { Some((&user).get_reviews(&mut **db, data.0.review_limit.unwrap(), data.0.review_offset.unwrap()).await) } else { None };
  let (total_reviews, reviews) = match review_data {
    Some((size, reviews)) => {
      let mut serialized_reviews: Vec<SerializedUserReview> = vec![];
      for review in reviews {
        serialized_reviews.push(review.serialize().await);
      }
      (Some(size), Some(serialized_reviews))
    }
    None => {
      if data.0.get_reviews {
        return Err(Status::BadRequest);
      }
      (None, None)
    }
  };

  let user: Option<SerializedUser> = if data.0.get_user_info { Some(user.serialize()) } else { None };

  Ok(
    Json(LookupOutput {
      user,
      allergies,
      reviews,
      total_reviews,
    })
  )
}
