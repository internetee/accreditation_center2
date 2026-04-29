# AccreditationCenter — Overview

Rails 8.1.3 | Ruby 3.4.4

- Database: static_parse — 12 tables
- Models: 12
- Routes: 122
- Auth: Devise + Pundit
- I18n: 2 locales (en, et)
- Assets: propshaft, importmap
- Databases: 2 (primary, queue)
- Performance: 22 issues detected

**Global before_actions:** authenticate_user!, configure_permitted_parameters

ALWAYS use MCP tools for context — do NOT read reference files directly.
Start with `detail:"summary"`. Read files ONLY when you will Edit them.