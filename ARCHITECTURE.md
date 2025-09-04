# Accreditation Center 2 - Architecture Documentation

## Overview

The Accreditation Center 2 is a simplified testing system designed for registrar accreditation, inspired by the Surveyor gem but tailored specifically for domain registry testing requirements. The system supports both theoretical (multiple choice) and practical (hands-on) testing with bilingual support (Estonian/English).

## Core Architecture

### Simplified Model Structure

Unlike the complex Surveyor gem, this system uses a streamlined approach:

```
Test
├── TestCategory (Domain Rule Categories)
│   └── Question
│       └── Answer
└── TestAttempt
    └── QuestionResponse
```

### Key Models

#### Test
- Represents an accreditation test
- Bilingual support (Estonian/English)
- Configurable time limits and passing scores
- Questions per category configuration

#### TestCategory
- Organizes questions by domain rule categories
- Links to specific domain rule references
- Configurable questions per category

#### Question
- Supports multiple choice and practical questions
- Bilingual text and help text
- Links to domain rule references through categories

#### Answer
- Multiple choice options with correct/incorrect flags
- Bilingual support
- Ordered display

#### TestAttempt
- Tracks user test sessions
- Handles timing and progress
- Manages test completion and scoring

#### QuestionResponse
- Records individual question answers
- Supports multiple correct answers
- Tracks "marked for later" status

## Key Features

### 1. Test Taking Process
- **Progress Tracking**: Real-time progress bar and question navigation
- **Time Management**: Automatic time tracking with 5-minute warnings
- **Question Navigation**: Jump to any question, mark for later
- **Multiple Correct Answers**: Support for questions with multiple correct options

### 2. Practical Testing
- **Registry Integration**: Connects to registry test environment
- **Dynamic Tasks**: Generates random domain names and objects
- **Validation**: Checks actual registry operations

### 3. Bilingual Support
- All content in Estonian and English
- Locale switching
- Automatic language detection

### 4. Admin Interface
- Test management (CRUD operations)
- Question and answer management
- Category organization
- User management

### 5. Notifications
- Automatic expiry warnings (14 days, 7 days, expiry day)
- Coordinator notifications
- Email-based notifications

## Database Design

### Key Tables

```sql
-- Core test structure
tests (id, title_et, title_en, description_et, description_en, time_limit_minutes, questions_per_category, passing_score_percentage, active, display_order)

test_categories (id, test_id, name_et, name_en, description_et, description_en, domain_rule_reference, questions_per_category, display_order, active)

questions (id, test_category_id, text_et, text_en, help_text_et, help_text_en, question_type, display_order, active, practical_task_data)

answers (id, question_id, text_et, text_en, display_order, correct)

-- Test attempts and responses
test_attempts (id, user_id, test_id, access_code, started_at, completed_at, score_percentage, passed)

question_responses (id, test_attempt_id, question_id, selected_answer_ids, marked_for_later, practical_response_data)
```

### Key Features
- **Array Support**: `selected_answer_ids` uses PostgreSQL arrays for multiple answers
- **JSONB**: `practical_task_data` and `practical_response_data` for flexible practical tasks
- **Indexing**: Optimized for common queries (active tests, user attempts, etc.)

## API Integration

### Registry Test Environment
The system integrates with a registry test environment for practical tasks:

1. **Task Generation**: Creates random domain names and objects
2. **User Interface**: Provides instructions and input forms
3. **Validation**: Checks actual registry operations via API
4. **Scoring**: Validates correct implementation

### Example Practical Task
```ruby
# Domain registration task
{
  type: 'domain_registration',
  domain_name: 'test1234.ee',
  instructions: {
    et: 'Registreeri domeen test1234.ee',
    en: 'Register domain test1234.ee'
  },
  expected_elements: ['domain_name', 'registrant_contact', 'admin_contact', 'tech_contact']
}
```

## Security Features

### Authentication & Authorization
- Devise-based user authentication
- Role-based access (user/admin)
- Session management

### Data Protection
- 30-day retention for detailed results
- Automatic cleanup of old data
- Secure access codes for test attempts

## Performance Considerations

### Database Optimization
- Proper indexing on frequently queried columns
- Efficient joins for test attempts and responses
- Array and JSONB operations for complex data

### Caching Strategy
- Test content caching
- User session caching
- Result caching for 30 days

## Deployment

### Docker Support
- Multi-stage Dockerfile
- Environment-based configuration
- Health checks

### Environment Configuration
- Database configuration
- Email settings
- Registry API credentials
- Locale settings

## Testing Strategy

### Unit Tests
- Model validations and methods
- Service layer testing
- Helper method testing

### Integration Tests
- Test taking flow
- Admin interface
- API integrations

### System Tests
- End-to-end test scenarios
- Performance testing
- Security testing

## Monitoring & Maintenance

### Logging
- Test attempt logging
- Error tracking
- Performance monitoring

### Maintenance Tasks
- Automatic data cleanup (30-day retention)
- Expiry notification scheduling
- Database optimization

## Future Enhancements

### Planned Features
1. **Advanced Analytics**: Detailed performance analytics
2. **Bulk Import**: CSV/Excel import for questions
3. **API Access**: REST API for external integrations
4. **Mobile Support**: Responsive design improvements
5. **Advanced Practical Tasks**: More complex registry operations

### Scalability Considerations
- Horizontal scaling with load balancers
- Database read replicas
- CDN for static assets
- Microservices architecture for specific components

## Comparison with Surveyor

### Simplifications Made
1. **Removed Complex Dependencies**: No skip logic or conditional questions
2. **Streamlined Models**: Fewer models, clearer relationships
3. **Focused Functionality**: Specific to accreditation needs
4. **Better Performance**: Optimized for the specific use case

### Enhancements Added
1. **Practical Testing**: Registry integration
2. **Bilingual Support**: Estonian/English throughout
3. **Time Management**: Real-time tracking and warnings
4. **Domain Rule Integration**: Links to specific registry rules
5. **Notification System**: Automatic expiry warnings

## Conclusion

The Accreditation Center 2 provides a focused, efficient solution for registrar accreditation testing while maintaining the flexibility and power of the original Surveyor concept. The simplified architecture makes it easier to maintain and extend while providing all the necessary features for a professional accreditation system. 