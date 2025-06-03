## Setup

1. Make sure Rust and Cargo are installed

2. Make sure watchexec is installed

```sh
cargo install --locked watchexec-cli
```

3. Run the server

```sh
cd backend
watchexec -r -e rs -- cargo run
```
