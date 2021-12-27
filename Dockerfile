#
# Build static binaries using several languages and build options, then
# generates a CSV of the binary sizes and an SVG of the results.
#
# See https://github.com/pablotron/tiny-binaries for details.
#

# old notes:
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
# Note: tested w/ both bullseye and alpine and the binary size results
# were identical.
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
# Note: tested w/ both bullseye and alpine and the binary size results
# were identical.
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
# Combined build environment for the following:
#
# * c-glibc
# * c-musl
# * c-asm
# * asm-naive
# * asm-opt
# * asm-elf
#
# Notes:
# * c-glibc packed with `upx --brute` works, but binary produces no
#   output. `upx --best` works fine.
# * upx refuses to pack c-musl, c-asm, asm-naive, asm-opt, and asm-elf.
#
FROM debian:bullseye-slim AS c-and-asm
COPY ./src/c-libc /src/c-glibc
COPY ./src/c-libc /src/c-musl
COPY ./src/c-asm /src/c-asm
COPY ./src/asm-naive /src/asm-naive
COPY ./src/asm-opt /src/asm-opt
COPY ./src/asm-elf-1 /src/asm-elf

RUN apt-get update && \
    apt-get install -y build-essential make gcc-10 musl-dev musl-tools nasm upx-ucl && \
    rm -rf /var/lib/apt/lists/* && \
    cd /src/c-glibc && \
    make && \
    upx --best -o hi-upx hi && \
    cd /src/c-musl && \
    make CC=musl-gcc && \
    cd /src/c-asm && \
    make && \
    cd /src/asm-naive && \
    make && \
    cd /src/asm-opt && \
    make && \
    cd /src/asm-elf && \
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
    rm -rf /var/lib/apt/lists/* && \
    cd /src/default && \
    cargo build --release && \
    upx --best -o /src/default/target/release/hi-upx /src/default/target/release/hi && \
    cd /src/opt-abort && \
    cargo build --release && \
    strip -s /src/opt-abort/target/release/hi && \
    upx --best -o /src/opt-abort/target/release/hi-upx /src/opt-abort/target/release/hi && \
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
    apt-get install -y python3-matplotlib python3-numpy && \
    rm -rf /var/lib/apt/lists/*

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
COPY --from=rust-1.57 /src/opt-abort/target/release/hi /out/bin/rust-1.57-abort
COPY --from=rust-1.57 /src/opt-abort/target/release/hi-upx /out/bin/rust-1.57-abort-upx
COPY --from=rust-1.57 /src/opt-all/target/release/hi /out/bin/rust-1.57-all
COPY --from=rust-1.57 /src/opt-all/target/release/hi-upx /out/bin/rust-1.57-all-upx
COPY --from=rust-1.57 /src/opt-lto/target/release/hi /out/bin/rust-1.57-lto
COPY --from=rust-1.57 /src/opt-lto/target/release/hi-upx /out/bin/rust-1.57-lto-upx
COPY --from=rust-1.57 /src/opt-oz/target/release/hi /out/bin/rust-1.57-oz
COPY --from=rust-1.57 /src/opt-oz/target/release/hi-upx /out/bin/rust-1.57-oz-upx
COPY --from=rust-1.57 /src/opt-strip/target/release/hi /out/bin/rust-1.57-strip
COPY --from=rust-1.57 /src/opt-strip/target/release/hi-upx /out/bin/rust-1.57-strip-upx
COPY --from=c-and-asm /src/c-glibc/hi /out/bin/c-glibc
COPY --from=c-and-asm /src/c-glibc/hi-upx /out/bin/c-glibc-upx
COPY --from=c-and-asm /src/c-musl/hi /out/bin/c-musl
# COPY --from=c-libc-musl /src/hi-upx /out/bin/c-musl-upx
COPY --from=c-and-asm /src/c-asm/hi /out/bin/c-asm
COPY --from=c-and-asm /src/asm-naive/hi /out/bin/asm-naive
COPY --from=c-and-asm /src/asm-opt/hi /out/bin/asm-opt
COPY --from=c-and-asm /src/asm-elf/hi /out/bin/asm-elf
COPY ./bin/gen.rb /gen.rb
COPY ./bin/plot.py /plot.py

# generate generate csv and svgs
RUN ["/gen.rb", "/out/data/sizes.csv", "/out/data/sizes-all.svg", "/out/data/sizes-tiny.svg"]

#
# Final image which copies generated binaries to /data/bin, generated
# SVGs to /data, and generated CSV to /data.
#
# To run this image, do this:
#
#   # create output directory
#   mkdir ./out && chmod 777 ./out
#
#   # copy csv and svgs to ./out
#   docker run --rm -it -v $(pwd)/out:/out pablotron/tiny-binaries
#
# You can inspect the generated binaries in `/data/bin` like this:
#
#   # execute shell in container
#   docker run --rm -it pablotron/tiny-binaries sh
#
#   # switch to output binary directory
#   cd /data/bin
#
#   # install file
#   apk add file
#
#   # verify that binaries are statically linked
#   file *
#
#   # verify binary file sizes
#   wc -c *
#
FROM alpine:3.15
RUN mkdir /data
COPY --from=data /out/data/sizes.csv /data/sizes.csv
COPY --from=data /out/data/sizes-all.svg /data/sizes-all.svg
COPY --from=data /out/data/sizes-tiny.svg /data/sizes-tiny.svg
COPY --from=data /out/bin /data/bin

# default command
CMD ["/bin/cp", "/data/sizes.csv", "/data/sizes-all.svg", "/data/sizes-tiny.svg", "/out"]
