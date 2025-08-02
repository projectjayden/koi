#[catch(500)]
pub fn internal_server_error() -> &'static str {
  "500 - An internal server error occurred"
}

#[catch(400)]
pub fn bad_request() -> &'static str {
  "400 - Request was invalid"
}

#[catch(401)]
pub fn unauthorized() -> &'static str {
  "401 - Login required"
}

#[catch(403)]
pub fn forbidden() -> &'static str {
  "403 - Get out"
}

#[catch(404)]
pub fn not_found() -> &'static str {
  "404 - Not found"
}

#[catch(418)]
pub fn im_a_teapot() -> &'static str {
  "418 - Clown detected"
}

#[catch(422)]
pub fn unprocessable_entity() -> &'static str {
  "422 - Wrong or missing fields"
}
