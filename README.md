# Accreditation Center

[![Maintainability](https://qlty.sh/gh/internetee/projects/accreditation_center2/maintainability.svg)](https://qlty.sh/gh/internetee/projects/accreditation_center2)
[![Code Coverage](https://qlty.sh/gh/internetee/projects/accreditation_center2/coverage.svg)](https://qlty.sh/gh/internetee/projects/accreditation_center2)

**Accreditation Center** is a modern, automated accreditation system for the `.ee` top-level domain (TLD). Built with Ruby on Rails 8, it streamlines the process of accrediting registrars and managing their compliance with the Estonian Internet Foundation's requirements.

## Project Overview

- **Purpose:** Automate and manage the accreditation process for registrars of the `.ee` TLD.
- **Audience:** Registry operators, registrar applicants, and compliance administrators.
- **Key Features:**
  - Online application and document submission for registrar accreditation
  - Automated workflow for application review, approval, and compliance checks
  - Secure document management and audit trails
  - Role-based access for registrars, reviewers, and administrators
  - Real-time notifications and messaging
  - Comprehensive reporting and analytics

## Getting Started

### Prerequisites

- **Ruby:** 3.4.4 (see `.ruby-version`)
- **PostgreSQL:** 12+
- **ImageMagick, libvips, or similar** (for file uploads, if required)
- **No Node.js or Yarn required** (JavaScript is managed via Importmaps)

### Setup

1. **Clone the repository:**
   ```sh
   git clone https://github.com/internetee/accreditation_center2.git
   cd accreditation_center2
   ```

2. **Install dependencies:**
   ```sh
   bundle install
   ```

3. **Set up the database:**
   ```sh
   bin/rails db:create db:schema:load
   ```

4. **Run the test suite:**
   ```sh
   bundle exec rspec
   ```

5. **Start the Rails server:**
   ```sh
   bin/rails server
   ```

### Configuration

- Copy `config/master.key.example` to `config/master.key` and set your credentials.
- Configure environment variables as needed in `config/application.yml.sample` (copy to `config/application.yml`) or your deployment environment.

### Testing Emails

- Run mailer specs:
  ```sh
  bundle exec rspec spec/mailers
  ```
- Open Rails mail previews in development:
  - Start server with `bin/rails server`
  - Visit `http://localhost:3000/rails/mailers`
  - Open `AccreditationMailer` previews to verify subject/body in browser

### Automatic Emails

Automatic accreditation emails are orchestrated by `RegistrarAccreditationNotificationsService` and delivered through `AccreditationMailer`.

- **Recipients:** registrar-facing emails are sent to `registrar.email`; admin notifications are sent to all admin users.
- **Test completion (not yet accredited):**
  - `practical_passed_not_accredited`
  - `theoretical_passed_not_accredited`
  - Sent only while registrar is not accredited.
- **Accreditation sync events:**
  - `accreditation_granted_or_reaccredited` for first accreditation.
  - `accreditation_granted_or_reaccredited` + `admin_accreditation_window_notice` for reaccreditation inside the 30-day window before previous expiry.
- **Daily expiry checks (`ExpiryCheckJob`):**
  - `expiry_30_days` when expiry is exactly 30 days away.
  - `expiry_or_passed` when expiry date is reached or passed.
- **One-time delivery guarantee:** events are deduplicated via `registrar_notification_events` (`registrar + event_type + cycle_key`) so repeated runs do not resend the same notification in the same cycle.

### Running in Docker (Development)

```sh
docker build -f Dockerfile.dev -t accreditation_center2-dev .
docker run --rm -it -p 3000:3000 accreditation_center2-dev
```

### Running Tests in CI

Tests are automatically run in GitHub Actions on every push and pull request. See `.github/workflows/ruby.yml` for details.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](LICENSE)
