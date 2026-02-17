# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-02-17

### Added

- `Tracer` struct with `step`, `input`, `output`, `nested` fields. [@systemic-engineer]
- `Tracer.new/4` constructor. [@systemic-engineer]
- `Tracer.ok?/1` and `Tracer.error?/1` — status detection from output value conventions. [@systemic-engineer]
- `Tracer.result/1` — normalizes any output to `{:ok, value}` or `{:error, reason}`. [@systemic-engineer]
- `Tracer.find/2` — recursive predicate search over the trace tree. [@systemic-engineer]
- `Tracer.reduce/3` — fold over all traces in the tree. [@systemic-engineer]
- `Tracer.root_causes/1` — finds leaf error traces (the true sources of failure). [@systemic-engineer]
- `Tracer.inspect/2` — shortcut for `inspect/2` with `custom_options`. [@systemic-engineer]
- `Inspect` implementation with color-coded tree rendering. [@systemic-engineer]
  - `depth: 0` — top level only (default)
  - `depth: N` — show N levels deep
  - `depth: :error` — only error branches
  - `depth: :infinity` — the full tree
- `Tracer.Nesting` — utilities for collecting traces during computation. [@systemic-engineer]
  - `traced_map/2` — map over an enumerable, collecting traces and results.
  - `traced_reduce_while/5` — like `traced_map/2` with early termination.
  - `collect_results/2`, `collect_oks/2`, `collect_errors/2` — result aggregation.
  - `reverse_results/1` — finalize step for accumulated results.

[Unreleased]: https://github.com/systemic-engineer/tracer/compare/v0.1.0...main
[0.1.0]: https://github.com/systemic-engineer/tracer/releases/tag/v0.1.0
