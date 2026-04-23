# AccreditationCenter — Overview

Rails 8.0.2.1 | Ruby 3.4.4

- Database: static_parse — 10 tables
- Models: 10
- Routes: 114
- Auth: Devise + Pundit
- I18n: 2 locales (en, et)
- Assets: propshaft, importmap
- Performance: 17 issues detected

**Global before_actions:** authenticate_user!, configure_permitted_parameters

ALWAYS use MCP tools for context — do NOT read reference files directly.
Start with `detail:"summary"`. Read files ONLY when you will Edit them.