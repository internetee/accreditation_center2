# Admin Guide: Accreditation Center 2 Administration

## Overview

This guide explains how administrators can manage the Accreditation Center 2 system, including test creation, user management, and system administration.

## System Architecture

The Accreditation Center 2 supports two types of tests:
- **Theoretical Tests**: Multiple choice questions testing domain registry knowledge
- **Practical Tests**: Hands-on tasks requiring actual registry operations

## Accessing the Admin Interface

1. **Login as Admin**: Use your admin credentials to access the system
2. **Admin Dashboard**: Go to `/admin` for system overview and statistics
3. **Navigation**: Use the admin menu to access different management sections

## Admin Dashboard

### Dashboard Overview
The admin dashboard (`/admin`) provides:
- **System Statistics**: Total tests, users, attempts, and pass rates
- **Recent Activity**: Latest test attempts and user activity
- **Expiring Accreditations**: Users whose accreditations are expiring soon
- **Quick Actions**: Direct links to create new tests and manage content

## Test Management

### Creating a New Test

1. **Navigate to Tests**: Go to `/admin/tests`
2. **Click "New Test"**: Start creating a new accreditation test
3. **Fill Basic Information**:
   - **Title (Estonian)**: Test title in Estonian
   - **Title (English)**: Test title in English
   - **Description (Estonian)**: Test description in Estonian
   - **Description (English)**: Test description in English

4. **Configure Test Settings**:
   - **Test Type**: Choose between "Theoretical" or "Practical"
   - **Time Limit**: How long users have to complete the test (1-480 minutes)
   - **Passing Score**: Minimum percentage required to pass (0-100%)
   - **Active**: Whether the test is available to users

5. **Save the Test**: Click "Save" to create the test

### Test Categories Management

Test categories are managed independently and can be associated with multiple tests:

1. **Navigate to Categories**: Go to `/admin/test_categories`
2. **Create New Category**:
   - **Name (Estonian)**: Category name in Estonian
   - **Name (English)**: Category name in English
   - **Description (Estonian)**: Category description in Estonian
   - **Description (English)**: Category description in English
   - **Domain Rule Reference**: Link to specific domain registry rule (e.g., "9.1", "10.4")
   - **Questions per Category**: How many questions to show from this category
   - **Domain Rule URL**: URL to the specific rule documentation
   - **Active**: Whether the category is available

**Example Categories:**
```
- Domain Registration Rules (9.1)
- Contact Management (10.4)
- Nameserver Configuration (11.2)
- Transfer Procedures (12.1)
- WHOIS Data Accuracy (13.3)
```

### Associating Categories with Tests

1. **Select Test**: Go to the test you want to configure
2. **Add Categories**: Associate existing categories with the test
3. **Set Display Order**: Determine the order of categories in the test
4. **Configure Questions**: Set how many questions to show from each category

### Question Management

Questions are managed within test categories:

1. **Select Category**: Go to `/admin/test_categories` and click on a category
2. **Add New Question**:
   - **Text (Estonian)**: Question text in Estonian
   - **Text (English)**: Question text in English
   - **Help Text (Estonian)**: Optional help text in Estonian
   - **Help Text (English)**: Optional help text in English
   - **Display Order**: Order of questions within the category
   - **Active**: Whether the question is available

3. **For Multiple Choice Questions**:
   - Add multiple answer options
   - Mark which answers are correct (can be multiple)
   - Set display order for answers
   - Provide bilingual answer text

### Practical Tasks Management

For practical tests, tasks are managed separately:

1. **Navigate to Practical Tasks**: Go to the test's practical tasks section
2. **Create New Task**:
   - **Title (Estonian/English)**: Task title in both languages
   - **Body (Estonian/English)**: Detailed task instructions
   - **Validator Configuration**: JSONB configuration for validation logic
   - **Active**: Whether the task is available

3. **Task Configuration**:
   - **Task Type**: Domain registration, contact creation, etc.
   - **Validation Rules**: Define what constitutes a correct response
   - **Dependencies**: Set up task dependencies if needed

### Allocators (Practical Data Seeding)

Allocators automatically create the temporary resources (domains, nameservers, transfer codes, etc.) that practical tasks reference via `{{ }}` variables. They run every time an attempt is provisioned (`Attempts::Provisioner`) and merge their output into the attempt’s `vars`, making the generated values available to both the task body and the validator configuration.

**How to set up allocators**
1. Open the practical task in `/admin/practical_tasks/:id`.
2. In the validator JSON (`validator -> allocators`) add an entry per allocator:
   ```json
   {
     "klass": "UpdateNameserversValidator",
     "config": { "nameservers": { "{{domain1}}": "{{ns1_1}}" } },
     "allocators": [
       { "name": "domain_pair", "config": { "use_faker": true } },
       { "name": "nameservers", "config": { "count": 2, "export": { "d1_prefix": "ns1_" } } }
     ]
   }
   ```
3. Save the task; the allocators will run automatically when a candidate receives the task.

**Available allocators**
- **`domain_pair`**: Generates two related domains (`domain1`, `domain2`; plus `domain2_ascii`) using ASCII + Estonian IDN labels. Configurable options include `use_faker`, explicit `base1/base2`, `tld`, and custom export keys. Use it for tasks that need two fresh domains to manipulate.
- **`nameservers`**: Produces randomized nameserver hostnames and exports them under configurable prefixes (defaults `ns1_` / `ns2_`). Accepts `count`, `use_faker`, and `export` overrides. Pair it with validators like `UpdateNameserversValidator`.
- **`domain_transfer_seed`**: Creates real domains under the `accr_bot` registrar (requires `ACCR_BOT_CONTACT_CODE`) and exports domain names + transfer codes (`xfer_domain`, `xfer_code`). Options: `count`, `tld`, `use_faker`, `export` key overrides, `auto_transfer_code`. Ideal for registrar-change or transfer tasks.

Tips:
- Keep allocator configs minimal in production; rely on defaults unless a scenario requires deterministic values.
- Allocators are idempotent—rerunning provisioning won’t duplicate data if the exported keys already exist. Use this to safely re-provision failed attempts.
- When adding new allocator types, register them in `Allocators::Registry` so the admin UI JSON can find them.

### Validators (Practical Task Checking)

Validators read the live registry state and decide whether a candidate performed the required operations correctly. Each practical task references a validator class plus JSON configuration that tailor the checks and error messages. When a candidate submits evidence (or when the system polls automatically), the validator returns a structured response: `passed` flag, `score`, `evidence`, `errors`, and API audit logs.

**How to configure validators**
1. Open a practical task and edit the `validator` JSON.
2. Set the validator class and any options it expects:
   ```json
   {
     "klass": "RegisterDomainsValidator",
     "config": {
       "periods": { "{{domain1}}": "1y" },
       "enforce_registrant_from_task1": true
     },
     "input_fields": [],
     "allocators": []
   }
   ```
3. Use allocator-exported variables (e.g., `{{domain1}}`, `{{ns1_1}}`) inside the config to keep scenarios dynamic.
4. If the validator requires user input (upload file, EPP log, etc.), add entries under `input_fields` so the UI renders the form elements.

**Common validator types**
- **RegisterDomainsValidator**: Confirms the listed domains exist and use the expected contacts/periods.
- **UpdateNameserversValidator**: Checks that required nameservers are present (supports additional NS records).
- **TransferDomainsValidator / ChangeRegistrantValidator / RenewDomainValidator**: Inspect domain history, transfer codes, registrant info, and renewal periods.
Each validator lives under `app/validators` and documents the expected config keys in comments.

Tips:
- After editing validator JSON, use the “Preview” button in the admin UI to ensure JSON is valid.
- Validator failures often include `api_audit` entries—review them to see which REPP call failed.
- When creating new validator classes, inherit from `BaseTaskValidator` so audit helpers, pass/fail helpers, and localization are available.

### Answer Management

Answers are managed within questions:

1. **Select Question**: Click on a question to manage its answers
2. **Add Answer Options**:
   - **Text (Estonian)**: Answer text in Estonian
   - **Text (English)**: Answer text in English
   - **Correct**: Check if this answer is correct
   - **Display Order**: Order of answers

3. **Multiple Correct Answers**: You can mark multiple answers as correct for questions that require multiple selections

## User Management

### Viewing Users

1. **User List**: Go to `/admin/users` to see all registered users
2. **Search and Filter**: Use the search functionality to find specific users
3. **User Details**: Click on a user to see their detailed information

### User Statistics

1. **Test History**: View all test attempts for a user
2. **Accreditation Status**: Check current accreditation status and expiry dates
3. **Performance Metrics**: View pass/fail rates and completion times
4. **Recent Activity**: See the user's latest test attempts

### Test Attempts Monitoring

1. **Test Attempts**: Go to `/admin/test_attempts` to monitor all test attempts
2. **Filter Options**: Filter by test, user, date range, or status
3. **Detailed Results**: View individual question responses and scores
4. **Export Data**: Export results for analysis

## Test Types

### Theoretical Tests

**Purpose:**
- Testing knowledge of domain registry rules
- Understanding procedures and requirements
- Validating theoretical knowledge

**Features:**
- Multiple choice questions
- Bilingual support (Estonian/English)
- Configurable time limits
- Multiple correct answers supported

**Example Question:**
```
Question: "Millised kontaktandmed on kohustuslikud domeeni registreerimisel?"
Answers:
- [✓] Registrant contact
- [✓] Admin contact  
- [✓] Tech contact
- [ ] Billing contact (optional)
```

### Practical Tests

**Purpose:**
- Testing hands-on skills
- Validating ability to perform actual registry operations
- Testing EPP command knowledge

**Features:**
- Real registry integration
- Configurable validation logic
- Task dependencies
- JSONB-based validation rules

**Example Task:**
```
Task: "Registreeri domeen test1234.ee"
Expected: User must create domain with proper contacts and nameservers
Validation: System checks if domain exists in test registry
```

## System Administration

### Authentication System

The system supports two types of users:
- **Admin Users**: Local authentication via Devise
- **Regular Users**: External API authentication via registry system

### User Authentication Flow

1. **Admin Login**: Direct login with admin credentials
2. **User Login**: External API authentication with registry credentials
3. **Session Management**: Token-based sessions for API users
4. **Role-Based Access**: Admin vs user permissions

### Notification System

The system includes automated notifications:
- **Expiry Warnings**: 14 days, 7 days, and expiry day notifications
- **Coordinator Alerts**: Admin notifications for expiring accreditations
- **Email Integration**: Automated email delivery
- **Background Jobs**: Scheduled notification processing

## Best Practices

### 1. Question Design

- **Clear and Specific**: Questions should be unambiguous
- **Bilingual**: Always provide both Estonian and English versions
- **Domain Rule Links**: Link questions to specific registry rules
- **Multiple Correct Answers**: Use when appropriate to test comprehensive understanding

### 2. Category Organization

- **Logical Grouping**: Group related questions together
- **Rule References**: Use consistent domain rule reference format
- **Balanced Coverage**: Ensure all important rules are covered
- **Progressive Difficulty**: Start with basic concepts, move to advanced

### 3. Test Configuration

- **Realistic Time Limits**: Give enough time for thoughtful answers (1-480 minutes)
- **Appropriate Passing Scores**: Set reasonable thresholds (typically 60-80%)
- **Question Distribution**: Ensure balanced coverage across categories
- **Test Types**: Choose appropriate test type (theoretical vs practical)

### 4. Content Management

- **Regular Updates**: Keep questions current with rule changes
- **Version Control**: Track changes to questions and answers
- **Quality Review**: Regularly review and improve questions
- **User Feedback**: Consider user feedback for improvements

## Test Management Operations

### Activating/Deactivating Tests

1. **Test List**: Go to `/admin/tests`
2. **Select Test**: Click on the test you want to modify
3. **Toggle Status**: Use "Activate" or "Deactivate" buttons
4. **Confirmation**: Confirm the action

### Editing Test Content

1. **Navigate to Content**: Go to the specific test/category/question
2. **Edit**: Click "Edit" button
3. **Modify**: Make your changes
4. **Save**: Save the changes

### Duplicating Tests

1. **Select Test**: Go to the test you want to duplicate
2. **Duplicate**: Click "Duplicate" button
3. **Modify**: Edit the duplicated test as needed
4. **Save**: Save the new test

### Test Categories Management

1. **Categories List**: Go to `/admin/test_categories`
2. **Create/Edit**: Add new categories or modify existing ones
3. **Associate with Tests**: Link categories to specific tests
4. **Display Order**: Set the order of categories in tests
