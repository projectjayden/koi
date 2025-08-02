use rocket::serde::{ json::Json, Serialize };

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct AppleOutput {
  pub applinks: AppLinks
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
pub struct AppLinks {
  pub apps: Vec<String>,
  pub details: Vec<Detail>
}

#[derive(Serialize)]
#[serde(crate = "rocket::serde")]
#[allow(non_snake_case)]
pub struct Detail {
  pub appID: String,
  pub paths: Vec<String>
}

/// # Apple App Site Association
/// For Universal Linking
/// 
/// **Route**: /.well-known/apple-app-site-association
#[get("/.well-known/apple-app-site-association")]
pub async fn aasa() -> Json<AppleOutput> {
  Json(AppleOutput {
    applinks: AppLinks {
      apps: vec![],
      details: vec![Detail {
        // TODO: use actual teamid and bundleid
        appID: "<teamid>.<bundleid>".to_string(),
        paths: vec!["/*".to_string()]
      }]
    }
  })
}
