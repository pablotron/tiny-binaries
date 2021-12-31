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
# Go 1.18beta1 build environment.
#
FROM golang:1.18beta1-alpine3.15 AS go-1.18beta1
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
# note: libc6-dev needed for build-std
RUN apt-get update && \
    apt-get install -y upx-ucl libc6-dev && \
    rm -rf /var/lib/apt/lists/* && \
# nightly disabled, all builds that use it fail w/ errors (see below)
#    rustup toolchain install nightly && \
#    rustup component add rust-src --toolchain nightly && \
    \
    cd /src/default && \
    cargo build --release && \
    upx --best -o /src/default/target/release/hi-upx /src/default/target/release/hi && \
    \
    cd /src/opt-abort && \
    cargo build --release && \
    strip -s /src/opt-abort/target/release/hi && \
    upx --best -o /src/opt-abort/target/release/hi-upx /src/opt-abort/target/release/hi && \
    \
    cd /src/opt-all && \
    cargo build --release && \
    strip -s /src/opt-all/target/release/hi && \
    upx --best -o /src/opt-all/target/release/hi-upx /src/opt-all/target/release/hi && \
    \
    cd /src/opt-lto && \
    cargo build --release && \
    upx --best -o /src/opt-lto/target/release/hi-upx /src/opt-lto/target/release/hi && \
    \
    cd /src/opt-oz && \
    cargo build --release && \
    upx --best -o /src/opt-oz/target/release/hi-upx /src/opt-oz/target/release/hi && \
    \
    cd /src/opt-strip && \
    cargo build --release && \
    strip -s /src/opt-strip/target/release/hi && \
    upx --best -o /src/opt-strip/target/release/hi-upx /src/opt-strip/target/release/hi
#
# disabled: building with 1.57 and with nightly fails as of 2021-12-31
# (see error below)
#     cd /src/opt-nostd && \
#     cargo +nightly build --release && \
#     strip -s /src/opt-nostd/target/release/hi && \
#     upx --best -o /src/opt-nostd/target/release/hi-upx /src/opt-nostd/target/release/hi
#
# error (as of 2021-12-31):
#
#    Compiling hi v0.1.0 (/src/opt-nostd)
# error[E0658]: use of unstable library feature 'rustc_private': this crate is being loaded from the sysroot, an unstable location; did you mean to load this crate from crates.io via `Cargo.toml` instead?
#  --> src/main.rs:4:1
#   |
# 4 | extern crate libc;
#   | ^^^^^^^^^^^^^^^^^^
#   |
#   = note: see issue #27812 <https://github.com/rust-lang/rust/issues/27812> for more information
#   = help: add `#![feature(rustc_private)]` to the crate attributes to enable
# 
# error[E0658]: use of unstable library feature 'rustc_private': this crate is being loaded from the sysroot, an unstable location; did you mean to load this crate from crates.io via `Cargo.toml` instead?
#   --> src/main.rs:11:3
#    |
# 11 |         libc::printf(HI.as_ptr() as *const _);
#    |         ^^^^^^^^^^^^
#    |
#    = note: see issue #27812 <https://github.com/rust-lang/rust/issues/27812> for more information
#    = help: add `#![feature(rustc_private)]` to the crate attributes to enable
# 
# For more information about this error, try `rustc --explain E0658`.
# error: could not compile `hi` due to 2 previous errors
#
#
# disabled: building with rust nightly fails as of 2021-12-31 (see error below):
#
#     cd /src/opt-build-std && \
#     cargo +nightly build -Z build-std=std,panic_abort --target x86_64-unknown-linux-gnu --release && \
#     strip -s /src/opt-build-std/target/x86_64-unknown-linux-gnu/hi && \
#     upx --best -o /src/opt-build-std/target/x86_64-unknown-linux-gnu/hi-upx /src/opt-build-std/target/x86_64-unknown-linux-gnu/hi && \
#     \
#     cd /src/opt-immediate-abort && \
#     cargo +nightly build -Z build-std=std,panic_abort -Z build-std-features=panic_immediate_abort --target x86_64-unknown-linux-gnu --release && \
#     strip -s /src/opt-immediate-abort/target/x86_64-unknown-linux-gnu/hi && \
#     upx --best -o /src/opt-immediate-abort/target/x86_64-unknown-linux-gnu/hi-upx /src/opt-immediate-abort/target/x86_64-unknown-linux-gnu/hi
#
# error (as of 2021-12-31):
#
#    Compiling hi v0.1.0 (/src/opt-build-std)
# error: linking with `cc` failed: exit status: 1
#   |
#   = note: "cc" "-m64" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/hi-296cb9c9b12daf6d.hi.ce2d2971-cgu.0.rcgu.o" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/hi-296cb9c9b12daf6d.hi.ce2d2971-cgu.1.rcgu.o" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/hi-296cb9c9b12daf6d.hi.ce2d2971-cgu.2.rcgu.o" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/hi-296cb9c9b12daf6d.1nr2jsqur0hlvfyk.rcgu.o" "-Wl,--as-needed" "-L" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps" "-L" "/src/opt-build-std/target/release/deps" "-L" "/usr/local/rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-unknown-linux-gnu/lib" "-Wl,--start-group" "-Wl,-Bstatic" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libstd-2ede5d5a398b0a09.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libpanic_abort-4cbc1cd2a7e06dc7.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libminiz_oxide-e81d5f96c6293b08.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libadler-23c928771041efe0.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libobject-a0158b834b2dcfed.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libmemchr-85e8f4dd026953b7.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libaddr2line-7e9caf678c9268ff.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libgimli-4b87eb8249573d2c.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libstd_detect-5adf2940020be34a.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/librustc_demangle-687dad39a49e0e8a.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libhashbrown-8330c668913a2d49.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/librustc_std_workspace_alloc-12d16b7a180e6d6b.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libunwind-b8843a49785ac559.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libcfg_if-741bf71f8071e80f.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/liblibc-0bb5282ec3a1823e.rlib" "-lutil" "-lrt" "-lpthread" "-lm" "-ldl" "-lc" "-lgcc_eh" "-lgcc" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/liballoc-a66551344c0dd558.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/librustc_std_workspace_core-8ee3eb9e8b72fbd2.rlib" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libcore-b09257d51e1eb693.rlib" "-Wl,--end-group" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libcompiler_builtins-5a6a922b1977480a.rlib" "-Wl,-Bdynamic" "-Wl,--eh-frame-hdr" "-Wl,-znoexecstack" "-L" "/usr/local/rustup/toolchains/nightly-x86_64-unknown-linux-gnu/lib/rustlib/x86_64-unknown-linux-gnu/lib" "-o" "/src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/hi-296cb9c9b12daf6d" "-Wl,--gc-sections" "-static" "-no-pie" "-Wl,-zrelro,-znow" "-Wl,-O1" "-nodefaultlibs"
#   = note: /usr/bin/ld: /src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libstd-2ede5d5a398b0a09.rlib(std-2ede5d5a398b0a09.std.b076dc03-cgu.5.rcgu.o): in function `std::env::home_dir':
#           std.b076dc03-cgu.5:(.text._ZN3std3env8home_dir17hd8ddda45f90ec3b5E+0xbc): warning: Using 'getpwuid_r' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
#           /usr/bin/ld: /src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libstd-2ede5d5a398b0a09.rlib(std-2ede5d5a398b0a09.std.b076dc03-cgu.10.rcgu.o): in function `<std::sys_common::net::LookupHost as core::convert::TryFrom<(&str,u16)>>::try_from':
#           std.b076dc03-cgu.10:(.text._ZN104_$LT$std..sys_common..net..LookupHost$u20$as$u20$core..convert..TryFrom$LT$$LP$$RF$str$C$u16$RP$$GT$$GT$8try_from17h39e199c9a3a9072bE+0x103): warning: Using 'getaddrinfo' in statically linked applications requires at runtime the shared libraries from the glibc version used for linking
#           /usr/bin/ld: /src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libcompiler_builtins-5a6a922b1977480a.rlib(compiler_builtins-5a6a922b1977480a.compiler_builtins.a1ca85d2-cgu.13.rcgu.o): in function `compiler_builtins::int::udiv::__udivti3':
#           compiler_builtins.a1ca85d2-cgu.13:(.text._ZN17compiler_builtins3int4udiv9__udivti317h79dfab6e95247a6dE+0x0): multiple definition of `__udivti3'; /usr/lib/gcc/x86_64-linux-gnu/10/libgcc.a(_udivdi3.o):(.text+0x0): first defined here
#           /usr/bin/ld: /src/opt-build-std/target/x86_64-unknown-linux-gnu/release/deps/libcompiler_builtins-5a6a922b1977480a.rlib(compiler_builtins-5a6a922b1977480a.compiler_builtins.a1ca85d2-cgu.14.rcgu.o): in function `__umodti3':
#           compiler_builtins.a1ca85d2-cgu.14:(.text.__umodti3+0x0): multiple definition of `__umodti3'; /usr/lib/gcc/x86_64-linux-gnu/10/libgcc.a(_umoddi3.o):(.text+0x0): first defined here
#           collect2: error: ld returned 1 exit status
# 
# error: could not compile `hi` due to previous error
#

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
COPY --from=go-1.18beta1 /src/hi-default /out/bin/go-1.18beta1-default
COPY --from=go-1.18beta1 /src/hi-ldflags /out/bin/go-1.18beta1-ldflags
COPY --from=go-1.18beta1 /src/hi-default-upx /out/bin/go-1.18beta1-default-upx
COPY --from=go-1.18beta1 /src/hi-ldflags-upx /out/bin/go-1.18beta1-ldflags-upx
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
# these all fail (see errors above)
# COPY --from=rust-1.57 /src/opt-nostd/target/release/hi /out/bin/rust-1.57-nostd
# COPY --from=rust-1.57 /src/opt-nostd/target/release/hi-upx /out/bin/rust-1.57-nostd-upx
# COPY --from=rust-1.57 /src/opt-build-std/target/x86_64-unknown-linux-gnu/hi /out/bin/rust-nightly-build-std
# COPY --from=rust-1.57 /src/opt-build-std/target/x86_64-unknown-linux-gnu/hi-upx /out/bin/rust-nightly-build-std-upx
# COPY --from=rust-1.57 /src/opt-immediate-abort/target/x86_64-unknown-linux-gnu/hi /out/bin/rust-nightly-immediate-abort
# COPY --from=rust-1.57 /src/opt-immediate-abort/target/x86_64-unknown-linux-gnu/hi-upx /out/bin/rust-nightly-immediate-abort-upx
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
