use base64::{ engine::general_purpose, Engine };
use jwt_simple::prelude::*;

#[allow(dead_code)]
pub fn main() {
  let keypair: Ed25519KeyPair = Ed25519KeyPair::generate();

  let private_bytes: Vec<u8> = keypair.to_bytes();
  let public_bytes: Vec<u8> = keypair.public_key().to_bytes();

  println!("ED25519_PRIVATE_KEY=\"{}\"", general_purpose::STANDARD.encode(private_bytes));
  println!("ED25519_PUBLIC_KEY=\"{}\"", general_purpose::STANDARD.encode(public_bytes));
}
