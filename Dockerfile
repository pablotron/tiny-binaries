# note: tested alpine and bullseye and the binaries are
# the same size, so i removed the bullseye tests
# go 1.15: ~2.0M
# go 1.15 + ldflags: ~1.5M
# go 1.17 + ldflags: ~1.2M
# go 1.17 + ldflags + upx: ~415k
# C: 700k
# C + upx: 280k
# asm: ~8k
# asm + nostdinc: 456B
# asm + nostdinc + slim: 368B

#
# Go 1.16 build environment.
#
FROM golang:1.16.12-alpine AS go-1.16
COPY ./src/go /src
WORKDIR /src

RUN apk update && \
    apk add upx && \
    go build -o hi-default hi.go && \
    go build -ldflags "-s -w" -o hi-ldflags hi.go && \
    upx --brute -o hi-default-upx hi-default && \
    upx --brute -o hi-ldflags-upx hi-ldflags

#
# Go 1.17 build environment.
#
FROM golang:1.17.5-alpine AS go-1.17
COPY ./src/go /src
WORKDIR /src

RUN apk update && \
    apk add upx && \
    go build -o hi-default hi.go && \
    go build -ldflags "-s -w" -o hi-ldflags hi.go && \
    upx --brute -o hi-default-upx hi-default && \
    upx --brute -o hi-ldflags-upx hi-ldflags

#
# C/glibc build environment.
#
# FIXME: should be combined with other C envs.
#
FROM debian:bullseye-slim AS c-libc-glibc
COPY ./src/c-libc /src
WORKDIR /src

RUN apt-get update && \
    apt-get install -y build-essential make gcc-10 upx-ucl && \
    make && \
    upx --best -o hi-upx hi

#
# C/musl build environment.
#
# FIXME: should be combined with other C envs.
#
FROM debian:bullseye-slim AS c-libc-musl
COPY ./src/c-libc /src
WORKDIR /src

RUN apt-get update && \
    apt-get install -y build-essential make gcc-10 musl-dev musl-tools upx-ucl && \
    make CC=musl-gcc
    # fails with "NotCompressible"
    # upx -o hi-upx hi

#
# C w/ inline asm build environment.
#
# FIXME: should be combined with other C envs.
#
FROM debian:bullseye-slim AS c-asm
COPY ./src/c-asm /src
WORKDIR /src

RUN apt-get update && \
    apt-get install -y build-essential nasm make gcc-10 upx-ucl && \
    make
#
# Unoptimized assembly build environment.
#
# FIXME: should be combined with other asm envs.
#
FROM debian:bullseye-slim AS asm-naive
COPY ./src/asm-naive /src
WORKDIR /src

RUN apt-get update && \
    apt-get install -y build-essential nasm make && \
    make

#
# Optimized assembly build environment.
#
# FIXME: should be combined with other asm envs.
#
FROM debian:bullseye-slim AS asm-opt
COPY ./src/asm-opt /src
WORKDIR /src

RUN apt-get update && \
    apt-get install -y build-essential nasm make && \
    make

#
# Optimized and packed assembly build environment.
#
# FIXME: should be combined with other asm envs.
#
FROM debian:bullseye-slim AS asm-elf-0
COPY ./src/asm-elf-0 /src
WORKDIR /src

RUN apt-get update && \
    apt-get install -y build-essential nasm make && \
    make

#
# Optimized and packed assembly build environment.
#
# FIXME: should be combined with other asm envs.
#
FROM debian:bullseye-slim AS asm-elf-1
COPY ./src/asm-elf-1 /src
WORKDIR /src

RUN apt-get update && \
    apt-get install -y build-essential nasm make && \
    make

#
# Rust 1.57 build environment
#
FROM rust:1.57-bullseye AS rust-1.57
COPY ./src/rust /src
WORKDIR /src

# note: upx --brute doesn't seem to work for rust binaries
# ref: https://github.com/johnthagen/min-sized-rust
RUN apt-get update && \
    apt-get install -y upx-ucl && \
    cd /src/default && \
    cargo build --release && \
    upx --best -o /src/default/target/release/hi-upx /src/default/target/release/hi && \
    cd /src/opt-all && \
    cargo build --release && \
    strip -s /src/opt-all/target/release/hi && \
    upx --best -o /src/opt-all/target/release/hi-upx /src/opt-all/target/release/hi && \
    cd /src/opt-lto && \
    cargo build --release && \
    upx --best -o /src/opt-lto/target/release/hi-upx /src/opt-lto/target/release/hi && \
    cd /src/opt-oz && \
    cargo build --release && \
    upx --best -o /src/opt-oz/target/release/hi-upx /src/opt-oz/target/release/hi && \
    cd /src/opt-strip && \
    cargo build --release && \
    strip -s /src/opt-strip/target/release/hi && \
    upx --best -o /src/opt-strip/target/release/hi-upx /src/opt-strip/target/release/hi

#
# generate CSV and SVGs
#
FROM ruby:3.0.3-slim-bullseye AS data
RUN mkdir -p /out/bin /out/data && \
    apt-get update && \
    apt-get install -y python3-matplotlib python3-numpy

# copy generated binaries
COPY --from=go-1.16 /src/hi-default /out/bin/go-1.16-default
COPY --from=go-1.16 /src/hi-ldflags /out/bin/go-1.16-ldflags
COPY --from=go-1.16 /src/hi-default-upx /out/bin/go-1.16-default-upx
COPY --from=go-1.16 /src/hi-ldflags-upx /out/bin/go-1.16-ldflags-upx
COPY --from=go-1.17 /src/hi-default /out/bin/go-1.17-default
COPY --from=go-1.17 /src/hi-ldflags /out/bin/go-1.17-ldflags
COPY --from=go-1.17 /src/hi-default-upx /out/bin/go-1.17-default-upx
COPY --from=go-1.17 /src/hi-ldflags-upx /out/bin/go-1.17-ldflags-upx
COPY --from=rust-1.57 /src/default/target/release/hi /out/bin/rust-1.57-default
COPY --from=rust-1.57 /src/default/target/release/hi-upx /out/bin/rust-1.57-default-upx
COPY --from=rust-1.57 /src/opt-all/target/release/hi /out/bin/rust-1.57-all
COPY --from=rust-1.57 /src/opt-all/target/release/hi-upx /out/bin/rust-1.57-all-upx
COPY --from=rust-1.57 /src/opt-lto/target/release/hi /out/bin/rust-1.57-lto
COPY --from=rust-1.57 /src/opt-lto/target/release/hi-upx /out/bin/rust-1.57-lto-upx
COPY --from=rust-1.57 /src/opt-oz/target/release/hi /out/bin/rust-1.57-oz
COPY --from=rust-1.57 /src/opt-oz/target/release/hi-upx /out/bin/rust-1.57-oz-upx
COPY --from=rust-1.57 /src/opt-strip/target/release/hi /out/bin/rust-1.57-strip
COPY --from=rust-1.57 /src/opt-strip/target/release/hi-upx /out/bin/rust-1.57-strip-upx
COPY --from=c-libc-glibc /src/hi /out/bin/c-glibc
COPY --from=c-libc-glibc /src/hi-upx /out/bin/c-glibc-upx
COPY --from=c-libc-musl /src/hi /out/bin/c-musl
# COPY --from=c-libc-musl /src/hi-upx /out/bin/c-musl-upx
COPY --from=c-asm /src/hi /out/bin/c-asm
COPY --from=asm-naive /src/hi /out/bin/asm-naive
COPY --from=asm-opt /src/hi /out/bin/asm-opt
COPY --from=asm-elf-1 /src/hi /out/bin/asm-elf
COPY ./bin/gen.rb /gen.rb
COPY ./bin/plot.py /plot.py
RUN ["/gen.rb", "/out/data/sizes.csv", "/out/data/sizes-all.svg", "/out/data/sizes-tiny.svg"]

#
# Final image which copies CSV and SVGs to /out
#
FROM alpine:3.15
RUN mkdir /data
COPY --from=data /out/data/sizes.csv /data/sizes.csv
COPY --from=data /out/data/sizes-all.svg /data/sizes-all.svg
COPY --from=data /out/data/sizes-tiny.svg /data/sizes-tiny.svg
ENTRYPOINT ["/bin/cp", "/data/sizes.csv", "/data/sizes-all.svg", "/data/sizes-tiny.svg", "/out"]
