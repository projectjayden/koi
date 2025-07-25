use crate::guards::revoke_jwt::RevokeJWT;
use rocket::http::Status;

/// # Logout
/// **Route**: /auth/logout
///
/// **Request method**: GET
///
/// **Input**: N/A
///
/// **Output**:
/// - 200 (success)
#[get("/logout")]
pub fn logout(_revoke_jwt: RevokeJWT) -> Status {
  Status::Ok
}
