# Repo Map
# Generated: 2026-03-18T00:44:34  |  Files: 23  |  Symbols: 164
# Reference this in CLAUDE.md with: @.codebase-context/repo_map.md

---

## codebase-context/codebase_context/chunker.py
  + chunk_id(filepath: str, symbol_name: str, start_line: int) -> str:
  + build_chunks(symbols: list[Symbol], filepath: str) -> list[Chunk]:
  + _truncate_to_tokens(text: str, max_tokens: int) -> str:

## codebase-context/codebase_context/cli.py
  + _update_gitignore(project_root: str) -> None:

## codebase-context/codebase_context/embedder.py
  class Embedder:
    + __init__(self, model_name: str = EMBED_MODEL):
    + _get_model(self) -> "TextEmbedding":
    + embed(self, texts: list[str]) -> list[list[float]]:
    + embed_one(self, text: str) -> list[float]:

## codebase-context/codebase_context/indexer.py
  class Indexer:
    + __init__(self, project_root: str, embedder: EmbeddingProvider | None = None):
    + full_index(self, show_progress: bool = True) -> IndexStats:
    + incremental_index(self, show_progress: bool = True) -> IndexStats:
    + index_file(self, filepath: str) -> int:
    + remove_file(self, filepath: str) -> None:
    + _regenerate_repo_map(self) -> None:
  + discover_files(project_root: str) -> list[str]:

## codebase-context/codebase_context/mcp_server.py
  + _setup_logging(project_root: str) -> None:
  + run_server() -> None:
  + _run_server(server) -> None:
  + _handle_search(retriever, arguments: dict):
  + _handle_get_symbol(retriever, arguments: dict):
  + _handle_get_repo_map(retriever, project_root: str):

## codebase-context/codebase_context/parser.py
  class UnsupportedLanguageError:
  class LanguageHandler:
    + extract_docstring(self, node, source_bytes: bytes) -> str | None: ...
    + extra_nodes(self, node) -> list: ...
  class _DefaultHandler:
    + extract_docstring(self, node, source_bytes: bytes) -> str | None:
    + extra_nodes(self, node) -> list:
  class _PythonHandler:
    + extract_docstring(self, node, source_bytes: bytes) -> str | None:
    + extra_nodes(self, node) -> list:
  class _TypeScriptHandler:
    + extract_docstring(self, node, source_bytes: bytes) -> str | None:
    + extra_nodes(self, node) -> list:
  + _get_node_text(node, source_bytes: bytes) -> str:
  + extract_signature(
  + extract_calls(node, source_bytes: bytes) -> list[str]:
  + _extract_declarator_name(node, source_bytes: bytes) -> str | None:
  + _get_call_name(node, source_bytes: bytes) -> str | None:
  + _extract_class_methods(
  + parse_file(filepath: str) -> list[Symbol]:

## codebase-context/codebase_context/repo_map.py
  + generate_repo_map(project_root: str, symbols_by_file: dict[str, list[Symbol]]) -> str:
  + _params_from_sig(sig: str) -> str:
  + write_repo_map(project_root: str, repo_map: str) -> None:

## codebase-context/codebase_context/retriever.py
  class Retriever:
    + __init__(self, project_root: str, embedder: EmbeddingProvider | None = None):
    + search(
    + get_symbol(self, name: str) -> list[RetrievalResult]:
    + get_repo_map(self, project_root: str) -> str:
  + _search_result_to_retrieval(sr: SearchResult) -> RetrievalResult:

## codebase-context/codebase_context/store.py
  class VectorStore:
    + __init__(self, project_root: str):
    + _get_or_create_collection(self):
    + upsert(self, chunks: list[Chunk], embeddings: list[list[float]]) -> None:
    + delete_by_filepath(self, filepath: str) -> None:
    + search(
    + get_by_symbol_name(self, name: str) -> list[SearchResult]:
    + count(self) -> int:
    + clear(self) -> None:

## codebase-context/codebase_context/utils.py
  + count_tokens(text: str) -> int:
  + slugify(text: str) -> str:
  + load_gitignore(project_root: str) -> pathspec.PathSpec:
  + is_ignored(filepath: str, project_root: str, gitignore: pathspec.PathSpec) -> bool:
  + find_project_root(start_path: str = ".") -> str:
  + load_index_meta(project_root: str):
  + load_symbols_cache(project_root: str) -> dict[str, list]:
  + save_symbols_cache(project_root: str, cache: dict[str, list]) -> None:
  + save_index_meta(project_root: str, meta) -> None:
  + format_results_for_agent(results: list) -> str:

## codebase-context/codebase_context/watcher.py
  class _CodebaseEventHandler:
    + __init__(self, indexer, project_root: str):
    + _should_handle(self, filepath: str) -> bool:
    + _schedule_flush(self) -> None:
    + _flush(self) -> None:
    + on_created(self, event):
    + on_modified(self, event):
    + on_deleted(self, event):
    + on_moved(self, event):
  + watch(project_root: str) -> None:
  + install_git_hook(project_root: str) -> None:
  + uninstall_git_hook(project_root: str) -> None:

## codebase-context/tests/test_chunker.py
  + make_symbol(name="my_func", sym_type="function", start=0, end=5,
  + test_chunk_has_context_prefix():
  + test_chunk_id_is_deterministic():
  + test_chunk_id_differs_for_different_inputs():
  + test_chunk_metadata_contains_required_fields():
  + test_long_chunk_truncated():
  + test_chunk_prefix_includes_parent_class():

## codebase-context/tests/test_indexer.py
  + test_discover_files_finds_py_and_ts(tmp_project):
  + test_discover_files_excludes_gitignore(tmp_project):
  + test_full_index_creates_chunks(tmp_project):
  + test_full_index_writes_repo_map(tmp_project):
  + test_incremental_index_skips_unchanged(tmp_project):
  + test_incremental_index_processes_changed_file(tmp_project):
  + test_index_file_returns_chunk_count(tmp_project):
  + test_remove_file_clears_chunks(tmp_project):

## codebase-context/tests/test_parser.py
  + test_parse_python_class_and_methods():
  + test_parse_python_module_functions():
  + test_parse_python_method_has_parent():
  + test_parse_python_function_no_parent():
  + test_parse_python_signature_format():
  + test_parse_typescript_class():
  + test_parse_typescript_interface():
  + test_parse_typescript_type_alias():
  + test_parse_typescript_arrow_function():
  + test_parse_syntax_error_returns_empty_or_partial():
  + test_parse_c_free_functions():
  + test_parse_c_function_language():
  + test_parse_c_struct():
  + test_parse_cpp_free_functions():
  + test_parse_cpp_class_and_methods():
  + test_parse_cpp_method_has_parent():
  + test_unsupported_extension_raises():

## codebase-context/tests/test_repo_map.py
  + make_sym(name, sym_type, parent=None, sig="def foo()", filepath="src/utils.py", lang="python"):
  + test_repo_map_includes_file_header():
  + test_repo_map_function_has_plus_prefix():
  + test_repo_map_methods_indented_under_class():
  + test_repo_map_header_contains_stats():
  + test_repo_map_token_estimate_under_target():
  + test_files_sorted_by_depth_then_alpha():

## codebase-context/tests/test_retriever.py
  + test_search_returns_results(indexed_project):
  + test_search_results_have_required_fields(indexed_project):
  + test_search_language_filter(indexed_project):
  + test_search_filepath_filter(indexed_project):
  + test_get_symbol_exact_match(indexed_project):
  + test_get_symbol_returns_empty_for_unknown(indexed_project):
  + test_get_repo_map_returns_content(indexed_project):
  + test_get_repo_map_not_indexed_message(tmp_path):

## codebase-context/tests/test_utils.py
  + test_count_tokens_basic():
  + test_count_tokens_empty():
  + test_slugify_basic():
  + test_slugify_safe_for_chroma():
  + test_find_project_root_with_git(tmp_path):
  + test_find_project_root_no_git(tmp_path):
  + test_load_gitignore_parses(tmp_path):
  + test_is_ignored_gitignore(tmp_path):
  + test_is_ignored_always_ignore(tmp_path):

## codebase-context/tests/fixtures/sample_c.c
  class UserService:
  + validate_email(const char *email) {
  + validate_password(const char *password) {

## codebase-context/tests/fixtures/sample_cpp.cpp
  class AuthService:
    + login(const std::string& email, const std::string& password) {
    + logout(const std::string& token) {
  + validate_email(const std::string& email) {
  + hash_password(const std::string& password) {

## codebase-context/tests/fixtures/sample_py.py
  class UserService:
    + create(self, email: str, password: str) -> "User":
    + find_by_email(self, email: str) -> "Optional[User]":
  + validate_email(email: str) -> str:
  + validate_password(password: str) -> bool:

## codebase-context/tests/fixtures/sample_ts.ts
  class AuthService:
    + login(email: string, password: string): Promise<User> {
  interface User
  type UserId
  + validateEmail(email: string): boolean {
  + hashPassword(password: string): string => {

## codebase-context/tests/fixtures/sample_project/src/api/auth.py
  class AuthRouter:
    + login(self, email: str, password: str) -> dict:
    + register(self, email: str, password: str) -> dict:
    + refresh(self, token: str) -> dict:

## codebase-context/tests/fixtures/sample_project/src/utils/validation.py
  + validate_email(email: str) -> str:
  + validate_password(password: str) -> bool:
