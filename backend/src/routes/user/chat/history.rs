use rocket::{ http::Status, serde::json::Json, State };
use crate::utils::t5::{ SessionStore, ChatExchange };
use dashmap::mapref::one::Ref;
use uuid::Uuid;

/// # Get Chat History
/// **Route**: /user/chat/history/<session_uuid>
///
/// **Request method**: GET
///
/// **Input**: None
///
/// **Output**:
/// ```ts
/// {
///   user_message: string;
///   assistant_response: string;
///   timestamp: number;
/// }[]; // array of chat exchanges
/// ```
#[get("/history/<session_uuid>")]
pub async fn history(session_uuid: &str, store: &State<SessionStore>) -> Result<Json<Vec<ChatExchange>>, Status> {
  let session_uuid: Option<Uuid> = Uuid::parse_str(session_uuid).ok();
  if session_uuid.is_none() {
    return Err(Status::BadRequest);
  }

  let session_uuid: Uuid = session_uuid.unwrap();
  let session: Ref<'_, Uuid, Vec<ChatExchange>> = store.get(&session_uuid).ok_or(Status::NotFound)?;

  Ok(Json(session.clone()))
}
