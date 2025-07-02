use std::time::{ SystemTime, UNIX_EPOCH };

/// Gets the current unix timestamp in seconds.
pub fn get_unix_seconds() -> u64 {
  SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs()
}

use rocket::{ http::{ private::cookie::Expiration, Cookie, SameSite }, time::OffsetDateTime };

/// Creates a private cookie.
pub fn create_cookie(name: &'static str, token: String) -> rocket::http::private::cookie::CookieBuilder<'static> {
  let one_week_from_now: i64 = (get_unix_seconds() + 86400 * 7).try_into().unwrap();
  let one_week_from_now: OffsetDateTime = OffsetDateTime::from_unix_timestamp(one_week_from_now).unwrap();
  let expiration: Expiration = Expiration::DateTime(one_week_from_now);

  // prettier-ignore
  Cookie::build((name, token))
    .path("/")
    .secure(true)
    .same_site(SameSite::Strict)
    .expires(expiration)
    .http_only(true)
}
