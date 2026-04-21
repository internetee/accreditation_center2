# frozen_string_literal: true

# Seed file for practical test and tasks

puts "Creating practical test..."

test = Test.find_or_create_by(slug: "practical-test") do |t|
  t.title_en = "Practical Test"
  t.title_et = "Praktika Test"
  t.test_type = :practical
  t.time_limit_minutes = 120
  t.passing_score_percentage = 100
  t.active = true
end

puts "Creating practical tasks..."

practical_tasks_data = [
  {
    test_id: test.id,
    title_en: "Contact creation",
    title_et: "Kontakti loomine",
    body_en: "Create 2 sets of contacts necessary for registering two domains. All required fields should be filled with correctly formatted data and where applicable, the field types indicated correctly. One registrant should be an organization, the other a private person. Make sure the email addresses of the registrant are deliverable to you.",
    body_et: "Loo 2 komplekti kontakte, mis on vajalikud domeenide registreerimiseks. Kõik nõutud väljad tuleb täita õigel kujul ja kohandatud, kui see on vajalik. Üks registrant peab olema organisatsioon, teine eraisik. Veendu, et registrantide e-posti aadressid oleksid saadaval.",
    validator: {
      klass: "CreateContactsValidator",
      config: {},
      input_fields: [
        { name: "org_contact_id", label_en: "Organization contact ID", label_et: "Organisatsiooni kontakt ID", required: true },
        { name: "priv_contact_id", label_en: "Private person contact ID", label_et: "Eraisiku kontakt ID", required: true }
      ],
      depends_on_task_ids: []
    },
    display_order: 1,
    active: true
  },
  {
    test_id: test.id,
    title_en: "Registering a domain",
    title_et: "Domeeni registreerimine",
    body_en: "Using your contacts from Task 1, register the following domains:\n- {{domain1}} for **1 year**\n- {{domain2}} for **2 years**\nAttach an application formatted like the one you will be using in production.",
    body_et: "Kasuta oma kontakte Task 1-st ja registreeri järgmised domeenid:\n- {{domain1}} **1 aasta**\n- {{domain2}} **2 aastat**\nLisa rakendus, mis on sarnane sellesse, mida sa kasutad tootuses.",
    validator: {
      klass: "RegisterDomainsValidator",
      config: {
        periods: { "{{domain1}}": "1y", "{{domain2}}": "2y" },
        enforce_registrant_from_task1: true
      },
      input_fields: [],
      allocators: [
        { name: "domain_pair", config: { use_faker: true } }
      ]
    },
    display_order: 2,
    active: true
  },
  {
    test_id: test.id,
    title_en: "Nameserver management",
    title_et: "Nimeserveri haldus",
    body_en: "Add/update nameservers of the domains created in the previous step.\nFor {{domain1}}: \n- Hostname {{ns1_1}}\nFor {{domain2}}:\n- Hostname {{ns2_1}}",
    body_et: "Lisa/uuda nimeserverid domeenidele, mis on loodud eelmises sammos.\n{{domain1}}:\n- Hostname {{ns1_1}}\n{{domain2}}:\n- Hostname {{ns2_1}}",
    validator: {
      klass: "UpdateNameserversValidator",
      config: {
        nameservers: { "{{domain1}}": "{{ns1_1}}", "{{domain2}}": "{{ns2_1}}" }
      },
      input_fields: [],
      allocators: [
        { name: "nameservers", config: { count: 1, use_faker: true } }
      ]
    },
    display_order: 3,
    active: true
  },
  {
    test_id: test.id,
    title_en: "Registrar change",
    title_et: "Registripidaja muutus",
    body_en: "Transfer domains {{ xfer_domain1 }} and {{ xfer_domain2 }} from other registrar.\nTransfer code: {{ xfer_code1 }}",
    body_et: "Üle kanda domeenid {{ xfer_domain1 }} ja {{ xfer_domain2 }} teiselt registripidajalt.\nÜlekandekood: {{ xfer_code1 }}",
    validator: {
      klass: "TransferDomainsValidator",
      config: {
        domains: ["{{xfer_domain1}}", "{{xfer_domain2}}"]
      },
      input_fields: [],
      allocators: [
        { name: "domain_transfer_seed", config: { count: 2, use_faker: true } }
      ]
    },
    display_order: 4,
    active: true
  },
  {
    test_id: test.id,
    title_en: "Domain renewal",
    title_et: "Domeeni pikendamine",
    body_en: "Renew domain {{ domain1 }} for 5 years.",
    body_et: "Pikenda domeeni {{ domain1 }} 5 aastaks.",
    validator: {
      klass: "RenewDomainValidator",
      config: { domain: "{{domain1}}", years: 6 },
      input_fields: [],
      allocators: []
    },
    display_order: 5,
    active: true
  },
  {
    test_id: test.id,
    title_en: "Registrant change",
    title_et: "Registreerija muutus",
    body_en: "Change the e-mail address for registrant of {{ xfer_domain }}, ensuring the new address is deliverable to you. Replace the registrant of {{ xfer_domain }} with the registrant of {{ domain1 }}. The confirmation message should be delivered to your email address, if you set up the contacts correctly. Act according to instruction in the message. Upon successful confirmation, registrant should be changed. If confirmation fails for some reason (you're unable to get the messages), use the alternative option of registrar-verified confirmation by using the option \"verified=yes\", either via EPP or portal. This will process the change request without delay.",
    body_et: "Muuda registreerija e-posti aadressi {{ xfer_domain }}, veendudes, et uus aadress oleks saadaval. Asenda {{ xfer_domain }} registreerija {{ domain1 }}-ga. Tähistuse teade tuleb saata sinu e-posti aadressile, kui kontaktid on seadistatud õigesti. Tegevus toimub vastavalt teadetele. Kui tähistuse kinnitamine ei õnnestu, kasuta alternatiivset valikut registreerija-kinnitatud tähistuse, kasutades valikut \"verified=yes\", kas EPP-i või portaali kaudu. See protsessib muutuse taotlust ilma viivitust.",
    validator: {
      klass: "ChangeRegistrantValidator",
      config: {
        xfer_domain: "{{xfer_domain}}",
        source_domain: "{{domain1}}"
      },
      input_fields: []
    },
    display_order: 6,
    active: true
  },
  {
    test_id: test.id,
    title_en: "Domain deletion",
    title_et: "Domeeni kustutamine",
    body_en: "Give the delete command for domain {{ xfer_domain }}, using the verified=yes option. If successful, domain should obtain pendingDelete status immediately.",
    body_et: "Käivita kustutamise käsk domeenile {{ xfer_domain }}, kasutades valikut \"verified=yes\". Kui õnnestub, domeen peaks saama pendingDelete staatusi kohe.",
    validator: {
      klass: "DeleteDomainVerifiedValidator",
      config: { domain: "{{ xfer_domain }}" },
      input_fields: []
    },
    display_order: 7,
    active: true
  },
  {
    test_id: test.id,
    title_en: "Invoice generation",
    title_et: "Arve loomine",
    body_en: "Log into the test environment web portal (if you haven't already) and create a new invoice. After reviewing the invoice that has been created, cancel it.",
    body_et: "Logi testi keskkonna veeb portaali (kui pole veel logitud) ja loo uus arve. Pärast arve vaatamist, kustuta see.",
    validator: {
      klass: "CreateAndCancelInvoiceValidator",
      config: { window_minutes: 15 },
      input_fields: []
    },
    display_order: 8,
    active: true
  }
]

practical_tasks_data.each do |task_data|
  task = PracticalTask.find_or_initialize_by(
    test_id: task_data[:test_id],
    display_order: task_data[:display_order]
  )

  task.assign_attributes(
    title_en: task_data[:title_en],
    title_et: task_data[:title_et],
    body_en: task_data[:body_en],
    body_et: task_data[:body_et],
    validator: task_data[:validator].to_json,
    active: task_data[:active]
  )

  if task.save
    puts "✓ Created/Updated: #{task.title_en}"
  else
    puts "✗ Failed to create: #{task.title_en} - #{task.errors.full_messages.join(', ')}"
  end
end

puts "Practical tasks seeding completed!"
