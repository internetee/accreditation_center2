# Accreditation Center 2 - Architecture Documentation

## Overview

The Accreditation Center 2 is a comprehensive testing system designed for registrar accreditation, supporting both theoretical (multiple choice) and practical (hands-on) testing with bilingual support (Estonian/English). The system integrates with external registry APIs and provides a complete accreditation management solution.

## Core Architecture

### Model Structure

The system uses a well-structured approach with clear relationships:

```
User (Devise Authentication)
├── TestAttempt
│   ├── QuestionResponse
│   └── PracticalTaskResult
└── Accreditation Management

Test
├── TestCategory (Many-to-Many)
│   └── Question
│       └── Answer
├── PracticalTask
└── TestAttempt

TestCategory
├── Question
└── Domain Rule References
```

### Key Models

#### User
- **Authentication**: Devise-based with username/email login
- **Roles**: User (registrar) and Admin
- **Accreditation Tracking**: Expiry dates, test history, statistics
- **API Integration**: External authentication via registry API
- **Key Methods**:
  - `passed_tests`, `failed_tests`, `completed_tests`
  - `latest_accreditation`, `accreditation_expiry_date`
  - `can_take_test?`, `test_statistics`

#### Test
- **Types**: Theoretical (0) and Practical (1)
- **Bilingual Support**: Estonian/English titles and descriptions
- **Configuration**: Time limits, passing scores, active status
- **Relationships**: Many-to-many with test categories
- **Features**: FriendlyId slugs, Ransack search
- **Key Methods**:
  - `total_questions`, `estimated_duration`
  - `has_theoretical_questions?`, `has_practical_tasks?`

#### TestCategory
- **Domain Rule Integration**: Links to specific registry rules
- **Bilingual Content**: Estonian/English names and descriptions
- **Configuration**: Questions per category, display order
- **URL References**: Links to domain rule documentation

#### Question
- **Types**: Multiple choice questions
- **Bilingual Support**: Estonian/English text and help text
- **Positioning**: Ordered within categories
- **Key Methods**:
  - `correct_answers`, `correct_answer_ids`
  - `randomize_answers`

#### Answer
- **Multiple Choice**: Text options with correct/incorrect flags
- **Bilingual Support**: Estonian/English text
- **Ordering**: Display order within questions

#### TestAttempt
- **Session Management**: Access codes, timing, completion tracking
- **Scoring**: Percentage scores, pass/fail status
- **Progress Tracking**: Started/completed timestamps
- **Key Methods**:
  - `completed?`, `in_progress?`, `failed?`
  - `time_remaining`, `time_elapsed`

#### QuestionResponse
- **Answer Tracking**: Multiple selected answers (PostgreSQL arrays)
- **Progress Management**: Marked for later functionality
- **Practical Tasks**: JSONB data for complex responses

#### PracticalTask
- **Dynamic Content**: JSONB validator configuration
- **Bilingual Instructions**: Estonian/English task descriptions
- **Validation**: Configurable validation logic
- **Dependencies**: Task dependency management

#### PracticalTaskResult
- **Result Tracking**: Links test attempts to practical tasks
- **Validation Results**: Stores validation outcomes

## Key Features

### 1. Test Taking Process
- **Progress Tracking**: Real-time progress bar and question navigation
- **Time Management**: Automatic time tracking with 5-minute warnings
- **Question Navigation**: Jump to any question, mark for later
- **Multiple Correct Answers**: Support for questions with multiple correct options
- **Session Management**: Access codes, time limits, completion tracking

### 2. Practical Testing
- **Registry Integration**: Connects to registry test environment via API
- **Dynamic Tasks**: Generates random domain names and objects
- **Validation**: Configurable validation logic via JSONB
- **Task Dependencies**: Complex task workflows
- **Result Tracking**: Detailed validation outcomes

### 3. Bilingual Support
- All content in Estonian and English
- Locale switching with I18n
- Automatic language detection
- Translatable model attributes

### 4. Admin Interface
- **Test Management**: CRUD operations for tests and categories
- **Question Management**: Create and organize questions with answers
- **User Management**: View user statistics and test history
- **Practical Task Management**: Configure validation logic
- **Dashboard**: Overview of system statistics

### 5. Authentication & Authorization
- **Dual Authentication**: Local admin users and external API users
- **Role-Based Access**: Admin vs regular user permissions
- **API Integration**: External registry authentication
- **Session Management**: Secure access codes and tokens

### 6. Notifications
- **Automatic Expiry Warnings**: 14 days, 7 days, expiry day
- **Coordinator Notifications**: Admin alerts for expiring accreditations
- **Email-Based Notifications**: Automated email system
- **Background Jobs**: Scheduled notification processing

## Database Design

### Key Tables

```sql
-- User management
users (id, email, encrypted_password, username, role, registrar_name, sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, created_at, updated_at)

-- Core test structure
tests (id, title_et, title_en, description_et, description_en, time_limit_minutes, passing_score_percentage, active, test_type, slug, created_at, updated_at)

test_categories (id, name_et, name_en, description_et, description_en, domain_rule_reference, questions_per_category, domain_rule_url, active, created_at, updated_at)

test_categories_tests (id, test_id, test_category_id, display_order, created_at, updated_at)

questions (id, test_category_id, text_et, text_en, help_text_et, help_text_en, question_type, display_order, active, created_at, updated_at)

answers (id, question_id, text_et, text_en, display_order, correct, created_at, updated_at)

-- Test attempts and responses
test_attempts (id, user_id, test_id, access_code, started_at, completed_at, score_percentage, passed, vars, created_at, updated_at)

question_responses (id, test_attempt_id, question_id, selected_answer_ids, marked_for_later, created_at, updated_at)

-- Practical tasks
practical_tasks (id, test_id, title_et, title_en, body_et, body_en, validator, display_order, active, created_at, updated_at)

practical_task_results (id, test_attempt_id, practical_task_id, result, created_at, updated_at)
```

### Key Features
- **Array Support**: `selected_answer_ids` uses PostgreSQL arrays for multiple answers
- **JSONB**: `validator` and `vars` for flexible configuration and variables
- **Indexing**: Optimized for common queries (active tests, user attempts, etc.)
- **Foreign Keys**: Proper referential integrity
- **Timestamps**: Full audit trail

## Services & Background Jobs

### Service Layer

#### ApiConnector (Base Service)
- **HTTP Client**: Faraday-based with SSL support
- **Error Handling**: Comprehensive error management
- **Authentication**: Token-based authentication
- **Configuration**: Timeout, SSL, logging options
- **Key Features**:
  - Generic request handling
  - SSL certificate support
  - Response standardization
  - Error categorization

#### AuthenticationService
- **External Authentication**: Registry API integration
- **User Creation**: Automatic user creation from API
- **Token Management**: Session token generation
- **Response Processing**: Standardized auth responses

#### Domain Services
- **DomainService**: Domain management operations
- **ContactService**: Contact management
- **InvoiceService**: Billing integration
- **ReppDomainService**: REPP protocol integration

#### Allocator Services
- **DomainPair**: Domain allocation logic
- **Nameservers**: Nameserver allocation
- **Registry**: Registry-specific operations
- **DomainTransferSeed**: Transfer operations

### Background Jobs

#### AccreditationExpiryNotificationJob
- **Scheduled Processing**: Automated expiry notifications
- **User Notifications**: 14-day, 7-day, and expiry day warnings
- **Coordinator Alerts**: Admin notifications for expiring accreditations
- **Email Integration**: Automated email delivery


