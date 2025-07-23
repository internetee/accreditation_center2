class PracticalTestService
  def initialize(question, test_attempt)
    @question = question
    @test_attempt = test_attempt
    @task_data = question.practical_task_data || {}
  end
  
  def generate_task
    case @task_data['type']
    when 'domain_registration'
      generate_domain_registration_task
    when 'contact_creation'
      generate_contact_creation_task
    when 'nameserver_creation'
      generate_nameserver_creation_task
    else
      raise "Unknown practical task type: #{@task_data['type']}"
    end
  end
  
  def validate_response(response_data)
    case @task_data['type']
    when 'domain_registration'
      validate_domain_registration(response_data)
    when 'contact_creation'
      validate_contact_creation(response_data)
    when 'nameserver_creation'
      validate_nameserver_creation(response_data)
    else
      false
    end
  end
  
  private
  
  def generate_domain_registration_task
    random_suffix = SecureRandom.hex(4)
    domain_name = "test#{random_suffix}.ee"
    
    {
      type: 'domain_registration',
      domain_name: domain_name,
      instructions: {
        et: "Registreeri domeen #{domain_name}",
        en: "Register domain #{domain_name}"
      },
      expected_elements: ['domain_name', 'registrant_contact', 'admin_contact', 'tech_contact']
    }
  end
  
  def validate_domain_registration(response_data)
    # This would connect to the registry test environment
    # to check if the domain was actually created
    domain_name = response_data['domain_name']
    
    # Mock validation for now - in real implementation this would:
    # 1. Connect to registry test environment
    # 2. Check if domain exists
    # 3. Verify required contacts are set
    # 4. Check if EPP commands were used correctly
    
    # For now, just check if the response contains expected data
    response_data['domain_name'].present? &&
    response_data['registrant_contact'].present? &&
    response_data['admin_contact'].present? &&
    response_data['tech_contact'].present?
  end
  
  def generate_contact_creation_task
    random_id = SecureRandom.hex(4)
    contact_id = "TEST#{random_id}"
    
    {
      type: 'contact_creation',
      contact_id: contact_id,
      instructions: {
        et: "Loo kontakt #{contact_id}",
        en: "Create contact #{contact_id}"
      },
      expected_elements: ['contact_id', 'name', 'email', 'phone', 'address']
    }
  end
  
  def validate_contact_creation(response_data)
    contact_id = response_data['contact_id']
    
    # Mock validation - would check registry test environment
    response_data['contact_id'].present? &&
    response_data['name'].present? &&
    response_data['email'].present? &&
    response_data['phone'].present? &&
    response_data['address'].present?
  end
  
  def generate_nameserver_creation_task
    random_suffix = SecureRandom.hex(4)
    nameserver_name = "ns#{random_suffix}.test.ee"
    
    {
      type: 'nameserver_creation',
      nameserver_name: nameserver_name,
      instructions: {
        et: "Loo nimiserver #{nameserver_name}",
        en: "Create nameserver #{nameserver_name}"
      },
      expected_elements: ['nameserver_name', 'ip_addresses']
    }
  end
  
  def validate_nameserver_creation(response_data)
    nameserver_name = response_data['nameserver_name']
    
    # Mock validation - would check registry test environment
    response_data['nameserver_name'].present? &&
    response_data['ip_addresses'].present? &&
    response_data['ip_addresses'].is_a?(Array) &&
    response_data['ip_addresses'].any?
  end
end 