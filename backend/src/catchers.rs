use rocket::Request;

#[catch(500)]
pub fn internal_server_error() -> &'static str {
  "An internal server error occurred."
}

#[catch(400)]
pub fn bad_request() -> &'static str {
  "Request was invalid."
}

#[catch(401)]
pub fn unauthorized() -> &'static str {
  "Please login to continue."
}

#[catch(404)]
pub fn not_found(req: &Request) -> String {
    format!("Sorry, '{}' is not a valid path.", req.uri())
}