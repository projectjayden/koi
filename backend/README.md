## Setup

1. Make sure Rust and Cargo are installed

2. Select this directory

```sh
cd backend
```

3. Make sure watchexec is installed

```sh
cargo install --locked watchexec-cli
```

4. Create a .env file

```sh
ED25519_PRIVATE_KEY=
ED25519_PUBLIC_KEY=
```

5. Put the `db.sqlite` in `/backend`

6. Run the server

```sh
watchexec -r -e rs -- cargo run
```
