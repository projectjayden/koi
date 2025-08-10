use rocket::{ data::{ ToByteUnit, ByteUnit, Data, FromData, Outcome }, http::Status, Request };
use rocket::serde::DeserializeOwned;
use serde_json::from_reader;
use std::io::Cursor;

/// **Output**:
/// - `LimitedJson<T>` (success)
/// - 400 (invalid JSON)
/// - 413 (payload exceeds 100 MiB)
pub struct LimitedJson<T>(pub T);

#[rocket::async_trait]
impl<'r, T: DeserializeOwned> FromData<'r> for LimitedJson<T> {
  type Error = String;

  async fn from_data(_request: &'r Request<'_>, data: Data<'r>) -> Outcome<'r, Self> {
    let limit: ByteUnit = (100).mebibytes();

    let bytes: Vec<u8> = match data.open(limit).into_bytes().await {
      Ok(data_read) if !data_read.is_complete() => {
        return Outcome::Error((Status::PayloadTooLarge, "Payload too large".into()));
      }
      Ok(data_read) => data_read.into_inner(),
      Err(_) => {
        return Outcome::Error((Status::BadRequest, "Failed to read body".into()));
      }
    };

    match from_reader(Cursor::new(bytes)) {
      Ok(value) => Outcome::Success(LimitedJson(value)),
      Err(_) => Outcome::Error((Status::UnprocessableEntity, "Invalid JSON".into())),
    }
  }
}
