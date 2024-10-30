FROM rust:latest
COPY . .
RUN cargo build --release
CMD ["./target/release/tcpproxy", "solanum:6667", "-l", "12345", "-p", "${SHIM_PASSWORD}"]

