#[macro_use]
extern crate rocket;

use rocket::{ http::{ private::cookie::Expiration, Cookie, CookieJar, SameSite }, time::OffsetDateTime };
use std::time::{ SystemTime, UNIX_EPOCH };

#[get("/cookie")]
fn cookie(cookies: &CookieJar<'_>) -> String {
  let token_cookie: Option<Cookie<'static>> = cookies.get_private("veryRealToken");

  match token_cookie {
    Some(token) => token.value().to_string(),
    None => {
      let current_time: u64 = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
      let one_week_from_now: i64 = (current_time + 86400 * 7).try_into().unwrap();
      let one_week_from_now: OffsetDateTime = OffsetDateTime::from_unix_timestamp(one_week_from_now).unwrap();
      let expiration: Expiration = Expiration::DateTime(one_week_from_now);

      // prettier-ignore
      let cookie: rocket::http::private::cookie::CookieBuilder<'_> = Cookie::build(("veryRealToken", "12345"))
        .path("/")
        .secure(true)
        .same_site(SameSite::Strict)
        .expires(expiration)
        .http_only(true);

      cookies.add_private(cookie);
      "no cookie".to_string()
    }
  }
}

#[get("/")]
fn index() -> &'static str {
  "Hello, world!"
}

#[launch]
fn rocket() -> _ {
  dotenvy::dotenv().ok();
  rocket::build().mount("/", routes![index, cookie])
}
