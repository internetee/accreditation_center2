# Theoretical Test Seed Data
# This file contains seed data for the theoretical test system

puts 'Seeding theoretical test data...'

# Create test categories
test_categories = [
  {
    name_et: "Kategooria 1",
    name_en: "Category 1",
    description_et: "",
    description_en: "",
    domain_rule_reference: "9.1",
    questions_per_category: 5,
    active: true,
    domain_rule_url: "https://google.com"
  },
  {
    name_et: "Kategooria 2", 
    name_en: "Category 2",
    description_et: "",
    description_en: "",
    domain_rule_reference: "10.4",
    questions_per_category: 5,
    active: true,
    domain_rule_url: "https://google.com"
  }
]

test_categories.each_with_index do |category_data, index|
  category = TestCategory.find_or_create_by(domain_rule_reference: category_data[:domain_rule_reference]) do |cat|
    cat.name_et = category_data[:name_et]
    cat.name_en = category_data[:name_en]
    cat.description_et = category_data[:description_et]
    cat.description_en = category_data[:description_en]
    cat.domain_rule_reference = category_data[:domain_rule_reference]
    cat.questions_per_category = category_data[:questions_per_category]
    cat.active = category_data[:active]
    cat.domain_rule_url = category_data[:domain_rule_url]
  end
  instance_variable_set("@category_#{index + 1}", category)
  puts "Created/Updated test category: #{category.name_en}"
end

# You can access categories as: @category_1, @category_2, etc.

# Create questions
questions_data = [
  {
    test_category_id: @category_1.id,
    text_et: "Kui registreerija ei ole .ee domeeninime pikendanud, pärast kui mitut päeva on Eesti Interneti SA-l (edaspidi: EIS) õigus .ee domeeninimi kustutada?",
    text_en: "If the registrant has not renewed a .ee domain name, after how many days does EIS (Estonian Internet Foundation) have the right to delete the .ee domain name?",
    help_text_et: "",
    help_text_en: "",
    question_type: "multiple_choice",
    display_order: 1,
    active: true
  },
  {
    test_category_id: @category_1.id,
    text_et: "Kas juriidiline isik saab olla .ee domeeninime Halduskontakt ja/või Tehniline kontakt?",
    text_en: "Can a legal entity be the administrative contact and/or technical contact of a .ee domain name?",
    help_text_et: "",
    help_text_en: "",
    question_type: "multiple_choice",
    display_order: 2,
    active: true
  },
  {
    test_category_id: @category_2.id,
    text_et: "Registreerija soovib registreerida com.ee domeeni. Kas ja kuidas see on talle võimalik?",
    text_en: "A registrant wishes to register a com.ee domain. Is it possible, and if so, how?",
    help_text_et: "",
    help_text_en: "",
    question_type: "multiple_choice",
    display_order: 1,
    active: true
  },
  {
    test_category_id: @category_2.id,
    text_et: "Millisel juhul on autoriseerimiskood vajalik ja kuidas selle edastamine käib?",
    text_en: "In which case is the authorization code required, and how is it transferred?",
    help_text_et: "",
    help_text_en: "",
    question_type: "multiple_choice",
    display_order: 2,
    active: true
  }
]

questions_data.each_with_index do |question_data, index|
  question = Question.find_or_create_by(
    test_category_id: question_data[:test_category_id],
    display_order: question_data[:display_order]
  ) do |q|
    q.text_et = question_data[:text_et]
    q.text_en = question_data[:text_en]
    q.help_text_et = question_data[:help_text_et]
    q.help_text_en = question_data[:help_text_en]
    q.question_type = question_data[:question_type]
    q.active = question_data[:active]
  end
  instance_variable_set("@question_#{index + 1}", question)
  puts "Created/Updated question: #{question.text_et[0..50]}..."
end

# Create answers for questions
answers_data = [
  # Answers for question 1 (domain deletion days)
  {
    question_id: @question_1.id,
    text_et: "15",
    text_en: "15",
    display_order: 1,
    correct: false
  },
  {
    question_id: @question_1.id,
    text_et: "20",
    text_en: "20", 
    display_order: 2,
    correct: false
  },
  {
    question_id: @question_1.id,
    text_et: "30",
    text_en: "30",
    display_order: 3,
    correct: false
  },
  {
    question_id: @question_1.id,
    text_et: "45",
    text_en: "45",
    display_order: 4,
    correct: true
  },

  # Answers for question 2 (legal entity as contact)
  {
    question_id: @question_2.id,
    text_et: "Jah",
    text_en: "Yes",
    display_order: 1,
    correct: true
  },
  {
    question_id: @question_2.id,
    text_et: "Ei",
    text_en: "No",
    display_order: 2,
    correct: false
  },

  # Answers for question 3 (com.ee domain registration)
  {
    question_id: @question_3.id,
    text_et: "com.ee domeeni võib registreerida iga füüsiline isik; ettevõttel võib olla mitu com.ee domeeni ja halduskontakt ei pea asuma Eestis.",
    text_en: "A com.ee domain can be registered by any natural person; a company may have multiple com.ee domains and no administrative contact in Estonia is required.",
    display_order: 1,
    correct: false
  },
  {
    question_id: @question_3.id,
    text_et: "com.ee domeeni võivad registreerida ainult Eestis registreeritud ettevõtted — välisettevõtted ei saa com.ee domeeni registreerida, isegi kui esitavad äriregistri tõendi.",
    text_en: "Only companies registered in Estonia may register a com.ee domain — foreign companies cannot register a com.ee domain, even if they provide a business registry certificate.",
    display_order: 2,
    correct: false
  },
  {
    question_id: @question_3.id,
    text_et: "com.ee domeeni saab registreerida ükskõik milline isik või organisatsioon ning Eesti-halduskontakti olemasolu ei ole nõutav; piiramatus arv domeene on lubatud.",
    text_en: "Any person or organization may register a com.ee domain; an administrative contact in Estonia is not required, and there is no limit on the number of domains.",
    display_order: 3,
    correct: false
  },
  {
    question_id: @question_3.id,
    text_et: "com.ee domeeni saab registreerida ainult juriidiline isik (ettevõte), kellel võib olla üksainus com.ee domeen ning kellel peab olema Eestis asuv halduskontakt. Välisettevõte võib registreerida com.ee domeeni, esitades äriregistri tõendi ja määrates halduskontakti Eestis.",
    text_en: "A com.ee domain can only be registered by a legal entity (company), which may have only one com.ee domain and must have an administrative contact located in Estonia. A foreign company may register a com.ee domain by submitting a business registry certificate and appointing an administrative contact in Estonia.",
    display_order: 4,
    correct: true
  },

  # Answers for question 4 (authorization code)
  {
    question_id: @question_4.id,
    text_et: "Autoriseerimiskood on vajalik uue domeeni registreerimisel ning selle väljastab Eesti Interneti Sihtasutus automaatselt registreerijale e-posti teel.",
    text_en: "The authorization code is required when registering a new domain, and the Estonian Internet Foundation automatically sends it to the registrant by email.",
    display_order: 1,
    correct: false
  },
  {
    question_id: @question_4.id,
    text_et: "Autoriseerimiskood on vajalik domeeni kustutamisel ning selle saadab uus registripidaja automaatselt praegusele registripidajale.",
    text_en: "The authorization code is required when deleting a domain, and the new registrar automatically sends it to the current registrar.",
    display_order: 2,
    correct: false
  },
  {
    question_id: @question_4.id,
    text_et: "Autoriseerimiskood on vajalik domeeni omaniku andmete muutmisel ning kood tuleb sisestada registripidaja iseteenindusse muudatuse kinnitamiseks.",
    text_en: "The authorization code is required when changing domain owner details, and it must be entered into the registrar's self-service portal to confirm the change.",
    display_order: 3,
    correct: false
  },
  {
    question_id: @question_4.id,
    text_et: "Autoriseerimiskood on vajalik .ee domeeni registripidaja vahetamisel või domeeni üleviimisel (transfer). Kood väljastab praegune registripidaja registreerijale ning see tuleb edastada uuele registripidajale domeeni halduse üleandmiseks.",
    text_en: "The authorization code is required when changing the .ee domain registrar or transferring the domain. The current registrar issues the code to the registrant, who must provide it to the new registrar to complete the domain transfer.",
    display_order: 4,
    correct: true
  }
]

answers_data.each do |answer_data|
  answer = Answer.find_or_create_by(
    question_id: answer_data[:question_id],
    display_order: answer_data[:display_order]
  ) do |a|
    a.text_et = answer_data[:text_et]
    a.text_en = answer_data[:text_en]
    a.correct = answer_data[:correct]
  end
  puts "Created/Updated answer for question #{answer.question_id}: #{answer.text_et[0..30]}..."
end

# Create the theoretical test
test_data = {
  title_et: "Teooria test",
  title_en: "Theoretical test",
  description_et: "",
  description_en: "",
  time_limit_minutes: 60,
  passing_score_percentage: 60,
  active: true,
  slug: "4fdxp9nj",
  test_type: 0
}

test = Test.find_or_create_by(slug: test_data[:slug]) do |t|
  t.title_et = test_data[:title_et]
  t.title_en = test_data[:title_en]
  t.description_et = test_data[:description_et]
  t.description_en = test_data[:description_en]
  t.time_limit_minutes = test_data[:time_limit_minutes]
  t.passing_score_percentage = test_data[:passing_score_percentage]
  t.active = test_data[:active]
  t.test_type = test_data[:test_type]
end

puts "Created/Updated test: #{test.title_en}"

# Associate test categories with the test
test_categories = TestCategory.where(active: true)
test_categories.each do |category|
  test.test_categories << category unless test.test_categories.include?(category)
  puts "Associated test category '#{category.name_en}' with test '#{test.title_en}'"
end

puts "Theoretical test seeding completed!"
puts "Summary:"
puts "- #{TestCategory.count} test categories"
puts "- #{Question.count} questions"
puts "- #{Answer.count} answers"
puts "- #{Test.count} tests"
