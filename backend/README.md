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

4. Create an env file in the root directory

```sh
ROCKET_SECRET_KEY=
```

5. Run the server

```sh
watchexec -r -e rs -- cargo run
```
