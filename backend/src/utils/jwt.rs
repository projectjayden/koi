use base64::{ engine::general_purpose, Engine };
use jwt_simple::prelude::*;
use uuid::Uuid;
use std::env;

pub fn generate_jwt(user_uuid: &String) -> Result<String, jwt_simple::Error> {
  let private_b64: String = env::var("ED25519_PRIVATE_KEY").expect("Missing private key");
  let private_bytes: Vec<u8> = general_purpose::STANDARD.decode(private_b64).expect("Invalid private key");
  let key_pair: Ed25519KeyPair = Ed25519KeyPair::from_bytes(&private_bytes).unwrap();

  let jwt_id: String = Uuid::new_v4().to_string();
  let claims: JWTClaims<NoCustomClaims> = Claims::create(Duration::from_days(1)).with_subject(user_uuid).with_jwt_id(jwt_id);

  let token: String = key_pair.sign(claims)?;
  Ok(token)
}

pub fn get_public_key() -> Result<Ed25519PublicKey, jwt_simple::Error> {
  let public_b64: String = env::var("ED25519_PUBLIC_KEY").expect("Missing public key");
  let public_bytes: Vec<u8> = general_purpose::STANDARD.decode(public_b64).expect("Invalid public key");
  Ed25519PublicKey::from_bytes(&public_bytes)
}
