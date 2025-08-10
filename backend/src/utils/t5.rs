use rocket::serde::{ Deserialize, Serialize };
use reqwest::{ Client, Response };
use dashmap::DashMap;
use std::sync::Arc;
use uuid::Uuid;

#[derive(Serialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct T5Request {
  /// The user's input prompt.
  input_text: String,
  /// Max length of the response, in characters.
  ///
  /// Defaults to `512`.
  max_length: u32,
  /// A number between `0` and `1` (inclusive) that determines how random the response will be.
  ///
  /// `0` means not random at all, `1` means very random.
  ///
  /// Defaults to `0.7`.
  temperature: f32,
}
impl T5Request {
  pub fn new(input_text: String, max_length: Option<u32>, temperature: Option<f32>) -> Self {
    let max_length: u32 = max_length.unwrap_or(512);
    let temperature: f32 = temperature.unwrap_or(0.7);

    Self { input_text, max_length, temperature }
  }
}

#[derive(Deserialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct T5Response {
  pub generated_text: String,
}

#[derive(Clone, Serialize)]
#[serde(crate = "rocket::serde", rename_all = "camelCase")]
pub struct ChatExchange {
  /// The user's message.
  pub user_message: String,
  /// The assistant's response.
  pub assistant_response: String,
  /// Unix timestamp of the exchange, in seconds.
  pub timestamp: u32,
}

/// Hash map to store conversations.
///
/// `{ [session_uuid]: Vec<ChatExchange> }`
pub type SessionStore = Arc<DashMap<Uuid, Vec<ChatExchange>>>;

pub async fn call_t5_service(input: &str) -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
  let client: Client = Client::new();

  let ml_url: String = std::env::var("ML_SERVICE_URL").expect("Missing ML_SERVICE_URL env");
  let request: T5Request = T5Request::new(input.to_string(), None, None);

  let response: Response = client.post(&format!("{}/generate", ml_url)).json(&request).timeout(std::time::Duration::from_secs(30)).send().await?;

  if !response.status().is_success() {
    return Err(format!("ML service error: {}", response.status()).into());
  }

  let t5_response: T5Response = response.json().await?;
  Ok(t5_response.generated_text)
}

/// Gets the context of the last 5 chat exchanges as a formatted string.
pub fn build_context(history: &[ChatExchange], current_message: &str) -> String {
  let mut context: String = String::new();

  let recent_history: Vec<&ChatExchange> = history.iter().rev().take(5).collect();

  for exchange in recent_history.iter().rev() {
    context.push_str(&format!("Human: {}\nAssistant: {}\n", exchange.user_message, exchange.assistant_response));
  }
  context.push_str(&format!("Human: {}\nAssistant: ", current_message));

  context
}
