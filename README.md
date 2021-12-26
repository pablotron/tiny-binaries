# Tiny Binaries

Tiny static x86-64 Linux binaries which do the following:

1. print `"hi!\n"` to standard output.
2. exit with an exit code of `0`.

The binaries were generated using a variety of languages and build
methods, then sorted by size.

## Results

Plot of all results (**Note:** [log scale][] X axis):

<img
  src='out/sizes-all.svg'
  width='100%'
  title="Static x86-64 Linux binary sizes (log scale)"
  alt="Static x86-64 Linux binary sizes (log scale)"
/>

Plot of tiny results (less than 1k, linear scale):

<img
  src='out/sizes-tiny.svg'
  width='100%'
  title="Tiny static x86-64 Linux binary sizes"
  alt="Tiny static x86-64 Linux binary sizes"
/>

Raw size results are available in the [`out/` directory](./out/) in
[CSV][] format.

## Languages and Build Methods

Generated using the following languages and build methods:

| Name | Language | Description |
| ---- | -------- | ----------- |
| `go-1.16-default` | [Go][] 1.16 | Default build options. |
| `go-1.16-ldflags` | [Go][] 1.16 | Built with `-ldflags="-s -w"`. |
| `go-1.16-default-upx` | [Go][] 1.16 | Built with defaults and packed with [upx][]. |
| `go-1.16-ldflags-upx` | [Go][] 1.16 | Built with `-ldflags="-s -w"` and packed with [upx][]. |
| `go-1.17-default` | [Go][] 1.17 | Default build options. |
| `go-1.17-ldflags` | [Go][] 1.17 | Built with `-ldflags="-s -w"`. |
| `go-1.17-default-upx` | [Go][] 1.17 | Built with defaults and packed with [upx][]. |
| `go-1.17-ldflags-upx` | [Go][] 1.17 | Built with `-ldflags="-s -w"` and packed with [upx][]. |
| `rust-1.57-default` | [Rust][] 1.57 | Built with `--release` and `build.rustflags = "-C target-feature=+crt-static"`. |
| `rust-1.57-default-upx` | [Rust][] 1.57 | Built with `--release`, `build.rustflags = "-C target-feature=+crt-static"`, and packed with [upx][]. |
| `rust-1.57-strip` | [Rust][] 1.57 | Built with `--release` and `build.rustflags = "-C target-feature=+crt-static"`, then stripped with `strip`. |
| `rust-1.57-strip-upx` | [Rust][] 1.57 | Built with `--release` and `build.rustflags = "-C target-feature=+crt-static"`, then stripped with `strip` and packed with [upx][]. |
| `rust-1.57-lto` | [Rust][] 1.57 | Built with `--release`, `build.rustflags = "-C target-feature=+crt-static"`, and `profile.release.lto = true`. |
| `rust-1.57-lto-upx` | [Rust][] 1.57 | Built with `--release`, `build.rustflags = "-C target-feature=+crt-static"`, and `profile.release.lto = true`, then packed with [upx][]. |
| `rust-1.57-oz` | [Rust][] 1.57 | Built with `--release`, `build.rustflags = "-C target-feature=+crt-static"`, and `profile.release.opt-level = "z"`. |
| `rust-1.57-oz-upx` | [Rust][] 1.57 | Built with `--release`, `build.rustflags = "-C target-feature=+crt-static"`, and `profile.release.opt-level = "z"`, then packed with [upx][]. |
| `rust-1.57-all` | [Rust][] 1.57 | Built with `--release`, `build.rustflags = "-C target-feature=+crt-static"`, `profile.release.opt-level = "z"`, and `profile.release.lto = true`, then stripped with `strip`. |
| `rust-1.57-all-upx` | [Rust][] 1.57 | Built with `--release`, `build.rustflags = "-C target-feature=+crt-static"`, `profile.release.opt-level = "z"`, and `profile.release.lto = true`, then stripped with `strip` and packed with [upx][]. |
| `c-glibc` | C | Statically linked against [glibc][]. |
| `c-glibc-upx` | C | Statically linked against [glibc][] and packed with [upx][]. |
| `c-musl` | C | Statically linked against [musl][]. |
| `c-asm` | C (w/inline asm) | This is just the `asm-opt` assembly, ported to horrid [gas][] syntax, and embedded in a largely pointless C wrapper. |
| `asm-naive` | Assembly | Unoptimized x86-64 assembly, built with [nasm][] and linked with `ld`. |
| `asm-opt` | Assembly | Optimized x86-64 assembly, built with [nasm][]. |
| `asm-elf` | Assembly | Optimized x86-64 assembly, built with [nasm][].  Code is embedded in unverified portions of the [ELF][] and program header. |

**Notes:**

* [Debian][] only packages [Go][] 1.15.15 as of December 2021.  Yeesh.
* Versions of `gcc`, `upx`, `ld`, `strip`, and `nasm` are from the
  current version of [Debian][].
* C compiled with [GCC][] 10.  I also tested with [Clang][], but the
  results did not appear to be substantially different.
* `c-glibc-upx` binary packed with `upx --brute` produced no output, so it uses
  `upx --best` instead.
* `upx` fails with `NotCompressible` when run against `c-musl`.
* `upx` refuses to compress any of the `asm` binaries.
* [Rust][] binaries packed with `upx --brute` produced no output, so they use
  `upx --best` instead.
* [Rust][] nightly has `cargo-features = ["strip"]` but it is not available in
  stable, so I used `strip -s` instead.
* ELF/PH overlap and unverified byte regions used by `asm-elf` were borrowed from
  [Tiny ELF Files: Revisited in 2021][tiny-elf].  Thanks Nathan!

## Build Instructions

There is a top-level `Dockerfile` which you can use to generate all
of the builds, the output [CSV][], and the output [SVGs][svg].

```sh
# build all stages
docker build -t pablotron/tiny-binaries .
```

You can save the generated [CSV][] and [SVGs][svg] to an output
directory like so:

```sh
# create output directory and set permissions
mkdir ./out && chmod 777 ./out

# bind mount output directory, then copy generated reports to output directory
docker run --rm -it -v $(pwd)/out:/out pablotron/tiny-binaries
```

[nasm]: https://www.nasm.us/
  "Netwide Assembler"
[svg]: https://en.wikipedia.org/wiki/Scalable_Vector_Graphics
  "Scalable Vector Graphics"
[csv]: https://en.wikipedia.org/wiki/Comma-separated_values
  "Comma-Separated Values"
[gas]: https://en.wikipedia.org/wiki/GNU_Assembler
  "GNU assembler (horrible AT&T syntax)"
[elf]: https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
  "Executable and Linkable Format"
[upx]: https://en.wikipedia.org/wiki/UPX
  "Ultimate Packer for eXecutables"
[glibc]: https://en.wikipedia.org/wiki/Glibc
  "GNU C library"
[musl]: https://en.wikipedia.org/wiki/Musl
  "musl C standard library"
[go]: https://golang.org/
  "Go programming language"
[rust]: https://www.rust-lang.org/
  "Rust programming language"
[debian]: https://debian.org/
  "Debian Linux distribution"
[tiny-elf]: https://nathanotterness.com/2021/10/tiny_elf_modernized.html
  "Tiny ELF Files: Revisited in 2021"
[log scale]: https://en.wikipedia.org/wiki/Logarithmic_scale
  "Logarithmic scale"
[gcc]: https://gcc.gnu.org/
  "GNU Compiler Collection"
[clang]: https://clang.llvm.org/
  "LLVM C language frontend compiler"
