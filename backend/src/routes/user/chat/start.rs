use rocket::{ http::Status, serde::json::Json, State };
use crate::utils::t5::{ ChatExchange, SessionStore };
use uuid::Uuid;

/// # Start Chat
/// **Route**: /user/chat/start
///
/// **Request method**: POST
///
/// **Input**: None
///
/// **Output**: `string` - session UUID
#[post("/start")]
pub async fn start(store: &State<SessionStore>) -> Result<Json<String>, Status> {
  let session_uuid: Uuid = Uuid::new_v4();
  let session: Vec<ChatExchange> = vec![];

  if store.contains_key(&session_uuid) {
    return Err(Status::Forbidden);
  }
  store.insert(session_uuid, session);

  Ok(Json(session_uuid.to_string()))
}
