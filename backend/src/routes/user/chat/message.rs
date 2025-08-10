use crate::utils::{ t5::{ SessionStore, ChatExchange, call_t5_service, build_context }, functions::get_unix_seconds };
use rocket::{ http::Status, serde::{ Serialize, json::Json }, State };
use dashmap::mapref::one::RefMut;
use uuid::Uuid;

#[derive(Serialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct ChatMessageResponse {
  /// Session UUID.
  session_uuid: String,
  /// Assistant's response.
  response: String,
}

/// # Send Message
/// **Route**: /user/chat/message/<session_uuid>
///
/// **Request method**: POST
///
/// **Input**: `string` - user's message
///
/// **Output**:
/// ```ts
/// {
///   response: string;
///   sessionUuid: string;
/// }
/// ```
#[post("/message/<session_uuid>", data = "<data>")]
pub async fn message(session_uuid: &str, store: &State<SessionStore>, data: Json<String>) -> Result<Json<ChatMessageResponse>, Status> {
  let session_uuid: Option<Uuid> = Uuid::parse_str(session_uuid).ok();
  if session_uuid.is_none() {
    return Err(Status::BadRequest);
  }

  let session_uuid: Uuid = session_uuid.unwrap();
  let mut session: RefMut<'_, Uuid, Vec<ChatExchange>> = store.get_mut(&session_uuid).ok_or(Status::NotFound)?;

  let context: String = build_context(&session, &data);

  let response: Option<String> = call_t5_service(&context).await.ok();
  if response.is_none() {
    return Err(Status::InternalServerError);
  }
  let response: String = response.unwrap();

  session.push(ChatExchange {
    user_message: data.to_string(),
    assistant_response: response.clone(),
    timestamp: get_unix_seconds() as u32,
  });

  Ok(
    Json(ChatMessageResponse {
      session_uuid: session_uuid.to_string(),
      response,
    })
  )
}
