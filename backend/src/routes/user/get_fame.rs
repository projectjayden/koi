use crate::{ guards::auth::AuthenticatedUser, models::users::user::{ GetFollowType, MiniUser } };
use rocket::{ http::Status, serde::{ json::Json, Deserialize } };
use rocket_db_pools::Connection;
use crate::utils::db::Db;

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct FameInput {
  /// Type of data to fetch.
  ///
  /// - 0 = followers
  /// - 1 = following
  pub r#type: u32,
  /// Number of followers/following to get.
  ///
  /// Defaults to `20`.
  pub limit: Option<u32>,
  /// Offset of followers/following.
  ///
  /// Defaults to `0`.
  pub offset: Option<u32>,
}

/// # Get Followers/Following
/// Gets a small amount of data for either the user's followers/following.
///
/// **Route**: /user/get-fame
///
/// **Request method**: POST
///
/// **Input**:
/// ```ts
/// {
///   type: 0 | 1;
///   limit?: number;
///   offset?: number;
/// }
/// ```
///
/// **Output**:
/// ```ts
/// [
///   number; // total followers/following
///   {
///     uuid: string;
///     name: string;
///     bio: string | null;
///     isSubscribed: boolean;
///     followers: number;
///     following: number;
///   }[];
/// ]
/// ```
#[post("/get-fame", data = "<data>")]
pub async fn get_fame(mut db: Connection<Db>, user: AuthenticatedUser, data: Json<FameInput>) -> Result<Json<(usize, Vec<MiniUser>)>, Status> {
  let limit: u32 = data.0.limit.unwrap_or(20);
  let offset: u32 = data.0.offset.unwrap_or(0);

  let follow_type: GetFollowType = match data.0.r#type {
    0 => GetFollowType::Followers,
    1 => GetFollowType::Following,
    _ => {
      return Err(Status::BadRequest);
    }
  };

  let (total_followers, followers) = user.0.get_fame(&mut db, follow_type, limit, offset).await;
  Ok(Json((total_followers, followers)))
}
