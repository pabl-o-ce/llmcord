# Start with a rust alpine image
FROM rust:alpine3.17 as build

# This is important, see https://github.com/rust-lang/docker-rust/issues/85
ENV RUSTFLAGS="-C target-feature=-crt-static"

# if needed, add additional dependencies here
RUN apk update && apk add --no-cache musl-dev openssl-dev

# create a new empty shell project
RUN USER=root cargo new --bin llmcord
WORKDIR /llmcord

# copy over your manifests
COPY ./Cargo.lock ./Cargo.toml ./

# this build step will cache your dependencies
RUN cargo build --release \
  && rm src/*.rs

# copy your source tree
COPY ./config.toml ./config.toml
COPY ./src ./src

# build for release
RUN rm ./target/release/deps/llmcord*
RUN cargo build --release --bin llmcord
RUN strip target/release/llmcord

########### Start final stage ###########

# Use the official alpine image as the final base image
FROM alpine:3.17

# if needed, install additional dependencies here
RUN apk add --no-cache libgcc

WORKDIR /usr/src/llmcord

# copy the build artifact from the build stage
COPY --from=build /llmcord/config.toml .
COPY --from=build /llmcord/target/release/llmcord .

RUN chmod +x ./llmcord

# Run the application
CMD ["./llmcord"]