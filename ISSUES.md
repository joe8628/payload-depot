# Architectural Issues

> Identified by automated review (2026-03-15). Fix sequentially — each issue has a status field.
> Numbering = priority order (1 = highest). Update `Status` as work progresses.

---

## Issue 1 — Two incompatible token counters

**Priority:** P0 | **Status:** Open
**Files:** `codebase-context/codebase_context/utils.py:16-20`, `codebase-context/codebase_context/repo_map.py:117-119`

### Problem
Two separate functions estimate token counts using different algorithms:

```python
# utils.py — word count heuristic
def count_tokens(text: str) -> int:
    return int(len(text.split()) * 1.3)

# repo_map.py — character count heuristic
def estimate_tokens(text: str) -> int:
    return len(text) // 4
```

`count_tokens` is used in `chunker.py` for chunk truncation; `estimate_tokens` is used for the repo map warning threshold. For code-heavy text, these can diverge by 2×, causing chunks to be truncated too aggressively or too permissively, and the repo map warning to fire at the wrong threshold.

### Solution
Delete `count_tokens` from `utils.py`. Replace all call sites in `chunker.py` with `estimate_tokens` from `repo_map.py` (or extract it to a shared location). `len(text) // 4` is closer to BPE tokenizer behavior for code. Document that it is a rough approximation.

---

## Issue 2 — `slugify` hash collision risk

**Priority:** P0 | **Status:** Open
**Files:** `codebase-context/codebase_context/utils.py:23-35`

### Problem
The ChromaDB collection name is derived by slugifying the absolute project root path. Long paths are truncated to 54 characters before appending an 8-char (32-bit) hash suffix:

```python
slug = slug[:54] + "-" + hash_suffix  # only 8 hex chars of sha256
```

Two different paths with the same 54-char prefix and the same 8-char hash suffix would silently share a ChromaDB collection, mixing their embeddings. 32 bits of hash is also weak for distinguishing many project paths.

### Solution
Use a longer hash suffix (at least 16 chars, 64 bits). Alternatively, derive the collection name entirely from the full sha256 of the resolved absolute path, keeping only enough characters to stay within ChromaDB's name length limit. Do not truncate the discriminating part of the path.

---

## Issue 3 — Incremental index re-parses the entire codebase

**Priority:** P1 | **Status:** Open
**Files:** `codebase-context/codebase_context/indexer.py:177-187`, `codebase-context/codebase_context/watcher.py:70-77`

### Problem
Both `Indexer._regenerate_repo_map()` and the watcher's `_flush()` re-parse **all files** in the project to regenerate the repo map, even when only one file changed:

```python
def _regenerate_repo_map(self, files: list[str]) -> None:
    for filepath in files:        # 'files' = ALL discovered files, not just changed ones
        symbols = parse_file(filepath)
```

A 1-file edit in a 1000-file project triggers 1000 re-parses. The watcher makes this worse: on every debounce flush, it calls `discover_files()` and re-parses everything again.

### Solution
Cache parsed symbols alongside `index_meta.json` (e.g., a `symbols_cache.json` keyed by `filepath → mtime → [Symbol]`). On incremental runs, only re-parse files whose mtime changed. Merge updated symbols into the cached map before generating the repo map. This reduces incremental re-parse cost from O(total_files) to O(changed_files).

---

## Issue 4 — Watcher race condition on repo map generation

**Priority:** P1 | **Status:** Open
**Files:** `codebase-context/codebase_context/watcher.py:50-62`, `codebase-context/codebase_context/watcher.py:70-77`, `codebase-context/codebase_context/watcher.py:119-141`

### Problem
The lock in `_flush()` is released before file processing and repo map regeneration begin. If two flush cycles overlap (possible because `threading.Timer` creates new threads), both can parse files concurrently and race to write `repo_map.md`:

```python
def _flush(self) -> None:
    with self._lock:
        pending = dict(self._pending)
        self._pending.clear()
    # lock released — a new flush can start here
    for filepath, event_type in pending.items():
        ...
    # both flushes generate and write conflicting repo maps
```

Additionally, on SIGINT the pending debounce timer is never cancelled, so `_flush()` can execute after the observer is stopped.

### Solution
Use a `ThreadPoolExecutor(max_workers=1)` for all flush executions. This serializes flushes without holding a broad lock across I/O. In the shutdown path (observer stop), cancel any pending timer with `self._timer.cancel()` before joining.

---

## Issue 5 — Absolute vs relative path inconsistency in indexer metadata

**Priority:** P1 | **Status:** Open
**Files:** `codebase-context/codebase_context/indexer.py:99`, `codebase-context/codebase_context/indexer.py:119`, `codebase-context/codebase_context/indexer.py:135-136`, `codebase-context/codebase_context/indexer.py:173-174`

### Problem
`full_index()` stores **absolute** paths as keys in `file_mtimes` (line 99). `incremental_index()` looks up by absolute path for the mtime check (line 119) but calls `store.delete_by_filepath(rel_path)` (line 136) with a **relative** path. `remove_file()` deletes from metadata using the absolute path key (line 174) but from the store using a relative path. These assumptions coordinate only coincidentally; any future refactoring risks a silent mismatch.

### Solution
Pick one canonical form — **relative paths** — for all internal storage: `file_mtimes` keys, store filepaths, and chunk IDs. Apply `os.path.relpath(filepath, self.root)` immediately after `discover_files()` and use that single representation everywhere.

---

## Issue 6 — Overly broad exception handlers hide real failures

**Priority:** P2 | **Status:** Open
**Files:** `codebase-context/codebase_context/store.py:57-62`, `store.py:86-90`, `store.py:105-112`, `codebase-context/codebase_context/mcp_server.py:43-47`

### Problem
Three methods in `store.py` catch all exceptions and return empty results, making ChromaDB corruption, out-of-memory errors, and real bugs indistinguishable from "no results found". In `mcp_server.py`, embedding model load failures at startup are caught and logged as warnings, but the server continues running and will crash on the first actual `search_codebase` call.

### Solution
- In `store.py`: catch only `chromadb`-specific exceptions. Let `RuntimeError`, `MemoryError`, etc. propagate.
- In `mcp_server.py`: if `_get_model()` fails at startup, exit immediately with a clear error message rather than continuing with a broken state.

---

## Issue 7 — Quadratic complexity in chunk truncation

**Priority:** P2 | **Status:** Open
**Files:** `codebase-context/codebase_context/chunker.py:77-89`

### Problem
`_truncate_to_tokens()` appends a line, then re-joins and re-counts tokens on every iteration:

```python
for line in lines:
    result_lines.append(line)
    if count_tokens("\n".join(result_lines)) > max_tokens:  # O(n) per iteration
        result_lines.pop()
        break
```

This is O(n²) in the number of lines. For a 200-line class body, that is ~40,000 string operations per chunk.

### Solution
Accumulate an approximate character budget inline without re-joining:

```python
budget = max_tokens * 4  # chars per token approximation
char_count = 0
for line in lines:
    char_count += len(line) + 1  # +1 for newline
    if char_count > budget:
        break
    result_lines.append(line)
```

---

## Issue 8 — Orphaned metadata entries for deleted files

**Priority:** P2 | **Status:** Open
**Files:** `codebase-context/codebase_context/indexer.py:31-35`, `codebase-context/codebase_context/indexer.py:99`, `codebase-context/codebase_context/indexer.py:119`

### Problem
`file_mtimes` in `index_meta.json` grows monotonically. Files deleted from disk are only removed if the watcher's `on_deleted` handler fires (which requires the watcher to be running). If files are deleted while the watcher is not running, their entries remain in metadata forever. The incremental index then calls `os.path.getmtime(f)` on non-existent files, which raises `FileNotFoundError` (not caught), or returns a stale value.

### Solution
At the start of `incremental_index()`, compute the set difference between `discover_files()` and `meta.file_mtimes.keys()`. Files present in metadata but missing from disk are orphans — delete their store entries and remove them from metadata. This makes orphan cleanup self-healing without requiring the watcher.

---

## Issue 9 — No embedding provider interface

**Priority:** P3 | **Status:** Open
**Files:** `codebase-context/codebase_context/embedder.py:17-67`, `codebase-context/codebase_context/indexer.py:49`, `codebase-context/codebase_context/retriever.py:49`

### Problem
`Embedder` is hard-coupled to `fastembed.TextEmbedding`. Swapping to a different embedding backend (OpenAI, Ollama, mock for tests) requires modifying `Embedder` directly. Additionally, `Indexer` and `Retriever` each create their own `Embedder()` instance, loading the ~200MB model twice in the same process.

### Solution
Define a `Protocol`:

```python
class EmbeddingProvider(Protocol):
    def embed(self, texts: list[str]) -> list[list[float]]: ...
    def embed_one(self, text: str) -> list[float]: ...
```

Accept it as a constructor argument in `Indexer` and `Retriever`. In `mcp_server.py`, construct one shared instance at startup and inject it into both.

---

## Issue 10 — Parser has no language plugin interface

**Priority:** P3 | **Status:** Open
**Files:** `codebase-context/codebase_context/parser.py:56-83`, `codebase-context/codebase_context/parser.py:161-171`, `codebase-context/codebase_context/parser.py:259-403`

### Problem
The `process_node()` inner function is ~145 lines of nested `if/elif` chains handling 5+ node types across 7 languages. Language-specific knowledge is scattered throughout: docstring extraction only works for Python, call extraction has separate branches per language, and arrow functions require special-casing in `walk_top_level()`. Adding a new language requires surgery across the entire function.

### Solution
Define a `LanguageHandler` protocol with per-language implementations:

```python
class LanguageHandler(Protocol):
    def extract_docstring(self, node, source: bytes) -> str | None: ...
    def is_named_symbol(self, node) -> bool: ...
    def symbol_name(self, node, source: bytes) -> str | None: ...
```

The main `parse_file()` loop selects the right handler and stays language-agnostic. Language-specific logic is isolated, independently testable, and easy to extend.

---

## Issue 11 — `utils.py` grab-bag with circular import

**Priority:** P3 | **Status:** Open
**Files:** `codebase-context/codebase_context/utils.py` (all), `codebase-context/codebase_context/utils.py:83-96`

### Problem
`utils.py` bundles six unrelated concerns: token counting, string slugification, gitignore handling, project root discovery, index metadata I/O, and result formatting. It also has a circular import to `indexer.py` resolved by a local import hack:

```python
def load_index_meta(project_root: str):
    from codebase_context.indexer import IndexMeta  # circular!
```

The `format_results_for_agent` function has no callers and is dead code.

### Solution
- Move `IndexMeta` to a new `models.py` with no dependencies. This breaks the cycle cleanly.
- Split utilities into focused modules: `fs.py` (gitignore, project root), `tokens.py` (token counting), keep `utils.py` only for what remains.
- Delete the dead `format_results_for_agent` function.

---

## Issue 12 — Repo map has no truncation, only a warning

**Priority:** P3 | **Status:** Open
**Files:** `codebase-context/codebase_context/repo_map.py:14`, `codebase-context/codebase_context/repo_map.py:92-96`

### Problem
For large projects, the repo map can exceed 50k+ tokens. The code logs a warning at 8k tokens but always writes the full map:

```python
if tokens > _WARN_TOKENS:
    logger.warning("Repo map is large...")
return result  # always the full map
```

When loaded via the `get_repo_map` MCP tool, an oversized map wastes Claude's entire context budget. The 8k token threshold is also too conservative (at ~4 chars/token, 8k tokens is only 32KB).

### Solution
Implement depth-capped truncation: include all files at depth ≤ 2 unconditionally, then greedily add deeper files until a configurable token budget is reached. Append a footer when truncated: `# [Truncated: N files omitted — run ccindex map --full to see all.]`. Raise the default warn threshold to something more practical (e.g., 32k tokens).

---

## Fix Log

| # | Issue | Status | Notes |
|---|-------|--------|-------|
| 1 | Incompatible token counters | Fixed | Unified on `len(text) // 4` in `utils.py`; removed `estimate_tokens` from `repo_map.py` |
| 2 | `slugify` collision risk | Fixed | Hash suffix extended from 8 to 16 hex chars (32→64 bit); path prefix trimmed to 46 chars |
| 3 | Incremental re-parse all files | Fixed | Added `symbols_cache.json`; `index_file`/`remove_file` maintain it; `_regenerate_repo_map` reads it instead of re-parsing |
| 4 | Watcher race condition | Fixed | Added `_flush_lock` to serialise flush executions; timer cancelled on SIGINT/SIGTERM before observer stops |
| 5 | Absolute/relative path inconsistency | Fixed | `file_mtimes` keys normalized to relative paths throughout `full_index`, `incremental_index`, and `remove_file` |
| 6 | Broad exception handlers | Fixed | `store.py` catches `ChromaError` only; `mcp_server.py` exits on model load failure |
| 7 | Quadratic chunk truncation | Fixed | Replaced O(n²) join-per-iteration with incremental char count against `max_tokens * 4` budget |
| 8 | Orphaned metadata entries | Fixed | `incremental_index` now purges store chunks, metadata, and cache for files no longer on disk |
| 9 | No embedding provider interface | Fixed | Added `EmbeddingProvider` Protocol; `Indexer`/`Retriever` accept optional injection; MCP server shares one instance |
| 10 | No language plugin interface | Fixed | Added `LanguageHandler` Protocol; `_PythonHandler`, `_TypeScriptHandler`, `_DefaultHandler` isolate per-language logic; `parse_file` selects handler by language name |
| 11 | `utils.py` circular import | Fixed | Moved `IndexMeta`/`IndexStats` to `models.py`; local import hack removed from `utils.py` |
| 12 | Repo map no truncation | Fixed | Depth-based truncation: files at depth ≤ 2 always included; deeper files added greedily within 32k token budget; footer appended when omitted |
