#[macro_use]
extern crate rocket;

#[get("/")]
fn index() -> &'static str {
  "Hello, world!"
}

#[get("/world")] // <- route attribute
fn world() -> &'static str {
  // <- request handler
  "hello, world!"
}

#[launch]
fn rocket() -> _ {
  rocket::build().mount("/", routes![index, world]).mount("/hello", routes![world])
}
