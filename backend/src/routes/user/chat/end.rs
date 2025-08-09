use rocket::{ http::Status, State };
use crate::utils::t5::SessionStore;
use uuid::Uuid;

/// # End Chat Session
/// **Route**: /user/chat/end/<session_uuid>
///
/// **Request method**: DELETE
///
/// **Input**: None
///
/// **Output**:
/// - 200 (success)
/// - 400 (invalid session id)
/// - 404 (session not found)
#[delete("/end/<session_uuid>")]
pub async fn end(session_uuid: &str, store: &State<SessionStore>) -> Status {
  let session_uuid: Option<Uuid> = Uuid::parse_str(session_uuid).ok();
  if session_uuid.is_none() {
    return Status::BadRequest;
  }

  let session_uuid: Uuid = session_uuid.unwrap();
  if store.remove(&session_uuid).is_none() {
    return Status::NotFound;
  }

  Status::Ok
}
