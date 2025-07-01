# Accreditation Center

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
- Configure environment variables as needed in `.env` or your deployment environment.

### Running in Docker (Development)

```sh
docker build -f Dockerfile.dev -t accreditation_center2-dev .
docker run --rm -it -p 3000:3000 accreditation_center2-dev
```

### Running Tests in CI

Tests are automatically run in GitHub Actions on every push and pull request. See `.github/workflows/ci.yml` for details.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](LICENSE)
