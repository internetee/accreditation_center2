# Admin Guide: How to Prepare Tests for Users

## Overview

This guide explains how administrators can prepare and manage accreditation tests for users in the Accreditation Center 2 system.

## Accessing the Admin Interface

1. **Login as Admin**: Use your admin credentials to access the system
2. **Navigate to Admin**: Go to `/admin/tests` to access the test management interface
3. **Admin Dashboard**: View all tests, categories, and user statistics

## Step-by-Step Test Preparation Process

### Step 1: Create a New Test

1. **Navigate to Tests**: Go to `/admin/tests`
2. **Click "New Test"**: Start creating a new accreditation test
3. **Fill Basic Information**:
   - **Title (Estonian)**: Test title in Estonian
   - **Title (English)**: Test title in English
   - **Description (Estonian)**: Test description in Estonian
   - **Description (English)**: Test description in English

4. **Configure Test Settings**:
   - **Time Limit**: How long users have to complete the test (in minutes)
   - **Questions per Category**: How many questions to show from each category
   - **Passing Score**: Minimum percentage required to pass (0-100%)
   - **Display Order**: Order in which tests appear to users
   - **Active**: Whether the test is available to users

5. **Save the Test**: Click "Save" to create the test

### Step 2: Create Test Categories

1. **Select Test**: Click on the test you want to add categories to
2. **Navigate to Categories**: Go to the "Categories" section
3. **Add New Category**:
   - **Name (Estonian)**: Category name in Estonian
   - **Name (English)**: Category name in English
   - **Description (Estonian)**: Category description in Estonian
   - **Description (English)**: Category description in English
   - **Domain Rule Reference**: Link to specific domain registry rule (e.g., "R-1.2.3")
   - **Questions per Category**: How many questions to show from this category
   - **Display Order**: Order of categories in the test

**Example Categories:**
```
- Domain Registration (R-1.2.3)
- Contact Management (R-2.1.1) 
- Nameserver Configuration (R-3.4.2)
- Transfer Procedures (R-4.1.5)
- WHOIS Data Accuracy (R-5.2.1)
```

### Step 3: Add Questions to Categories

1. **Select Category**: Click on a category to add questions
2. **Add New Question**:
   - **Question Type**: Choose between "Multiple Choice" or "Practical"
   - **Text (Estonian)**: Question text in Estonian
   - **Text (English)**: Question text in English
   - **Help Text (Estonian)**: Optional help text in Estonian
   - **Help Text (English)**: Optional help text in English
   - **Display Order**: Order of questions within the category

3. **For Multiple Choice Questions**:
   - Add multiple answer options
   - Mark which answers are correct (can be multiple)
   - Set display order for answers

4. **For Practical Questions**:
   - Configure task type (domain registration, contact creation, etc.)
   - Set up validation criteria
   - Define expected elements

### Step 4: Configure Answers

1. **Select Question**: Click on a question to manage its answers
2. **Add Answer Options**:
   - **Text (Estonian)**: Answer text in Estonian
   - **Text (English)**: Answer text in English
   - **Correct**: Check if this answer is correct
   - **Display Order**: Order of answers

3. **Multiple Correct Answers**: You can mark multiple answers as correct for questions that require multiple selections

## Question Types

### Multiple Choice Questions

**Use for:**
- Testing knowledge of domain registry rules
- Understanding procedures and requirements
- Validating theoretical knowledge

**Example:**
```
Question: "Millised kontaktandmed on kohustuslikud domeeni registreerimisel?"
Answers:
- [✓] Registrant contact
- [✓] Admin contact  
- [✓] Tech contact
- [ ] Billing contact (optional)
```

### Practical Questions

**Use for:**
- Testing hands-on skills
- Validating ability to perform actual registry operations
- Testing EPP command knowledge

**Example:**
```
Task: "Registreeri domeen test1234.ee"
Expected: User must create domain with proper contacts and nameservers
Validation: System checks if domain exists in test registry
```

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

- **Realistic Time Limits**: Give enough time for thoughtful answers
- **Appropriate Passing Scores**: Set reasonable thresholds (typically 70-80%)
- **Question Distribution**: Ensure balanced coverage across categories

### 4. Content Management

- **Regular Updates**: Keep questions current with rule changes
- **Version Control**: Track changes to questions and answers
- **Quality Review**: Regularly review and improve questions
- **User Feedback**: Consider user feedback for improvements

## Managing Existing Tests

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

### Duplicating Questions

1. **Select Question**: Go to the question you want to duplicate
2. **Duplicate**: Click "Duplicate" button
3. **Modify**: Edit the duplicated question as needed
4. **Save**: Save the new question

## User Management

### Viewing User Results

1. **Test Results**: Go to `/admin/test_attempts`
2. **Filter**: Filter by test, user, or date range
3. **Details**: Click on individual attempts to see detailed results
4. **Export**: Export results for analysis

### User Statistics

1. **User List**: Go to `/admin/users`
2. **User Details**: Click on a user to see their test history
3. **Statistics**: View pass/fail rates and completion times
4. **Accreditation Status**: Check current accreditation status

## Quality Assurance

### Testing Your Tests

1. **Preview Mode**: Use preview mode to see how tests appear to users
2. **Test Runs**: Take the test yourself to verify functionality
3. **Peer Review**: Have other admins review your questions
4. **User Testing**: Get feedback from actual users

### Monitoring and Analytics

1. **Success Rates**: Monitor question success rates
2. **Time Analysis**: Check if time limits are appropriate
3. **Difficulty Assessment**: Adjust question difficulty based on results
4. **User Feedback**: Collect and act on user feedback

## Troubleshooting

### Common Issues

1. **Questions Not Appearing**: Check if questions are marked as active
2. **Categories Empty**: Ensure categories have questions assigned
3. **Test Not Available**: Verify test is marked as active
4. **Scoring Issues**: Check answer configurations

### Support

- **Documentation**: Refer to this guide and system documentation
- **Admin Community**: Connect with other admins for best practices
- **Technical Support**: Contact technical team for system issues

## Security Considerations

### Access Control

- **Admin Only**: Ensure only authorized admins can modify tests
- **Audit Trail**: All changes are logged for accountability
- **Backup**: Regular backups of test content
- **Version Control**: Track changes to prevent unauthorized modifications

### Data Protection

- **User Privacy**: Protect user test results and personal data
- **Secure Access**: Use secure authentication for admin access
- **Data Retention**: Follow data retention policies
- **Compliance**: Ensure compliance with data protection regulations

This guide provides a comprehensive overview of how to prepare and manage tests in the Accreditation Center 2 system. Regular review and updates of this guide will ensure it remains current with system improvements and best practices. 