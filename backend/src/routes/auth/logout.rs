use rocket::http::{ Cookie, CookieJar, Status };

/// # Logout
/// **Route**: /auth/logout
///
/// **Request method**: GET
///
/// **Input**: N/A
///
/// **Output**:
/// - 200 (success)
/// - 400 (error)
#[get("/logout")]
pub fn logout(cookies: &CookieJar<'_>) -> Status {
  let token_cookie: Option<Cookie<'static>> = cookies.get_private("auth_token");

  match token_cookie {
    Some(token) => {
      cookies.remove_private(token);
      Status::Ok
    }
    None => Status::BadRequest,
  }
}
