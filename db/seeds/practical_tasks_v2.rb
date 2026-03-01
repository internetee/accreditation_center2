# frozen_string_literal: true

puts "Creating practical test v2..."

test_v2 = Test.find_or_create_by(slug: "practical-test-v2") do |t|
  t.title_en = "Practical Test v2"
  t.title_et = "Praktiline test v2"
  t.test_type = :practical
  t.time_limit_minutes = 120
  t.passing_score_percentage = 100
  t.active = true
end

puts "Creating practical tasks for v2..."

tasks_v2 = [
  {
    display_order: 1,
    title_en: "Create private person contact",
    title_et: "Loo eraisikust kontakt",
    body_en: "Create a private person contact for yourself that will be used for domain registration. Fill all required fields with correctly formatted data and indicate field types where applicable. Make sure the registrant email address is deliverable to you.",
    body_et: "Loo enda jaoks eraisikust kontakt, mis on vajalik domeeni registreerimiseks. Kõik nõutud väljad tuleb täita õigel kujul ning vajadusel märgi väljade tüübid korrektselt. Veendu, et registreerija e-posti aadress oleks sulle kättesaadav.",
    validator: {
      klass: "SingleContactValidator",
      config: {
        expected_type: "priv",
        input_key: "priv_contact_id",
        window_minutes: 15
      },
      input_fields: [
        { name: "priv_contact_id", label_en: "Private contact ID", label_et: "Eraisiku kontakti ID", required: true }
      ],
      depends_on_task_ids: []
    }
  },
  {
    display_order: 2,
    title_en: "Register domain for private contact",
    title_et: "Registreeri domeen eraisikule",
    body_en: "Using the contact from Task 1, register the domain {{domain1}} for 1 year.",
    body_et: "Kasuta 1. ülesandes loodud kontakti ja registreeri domeen {{domain1}} 1 aastaks.",
    validator: {
      klass: "RegisterSingleDomainValidator",
      config: {
        domain_template: "{{domain1}}",
        period: "1y",
        registrant_var: "priv_contact_id"
      },
      input_fields: [],
      allocators: [
        { name: "domain_pair", config: { use_faker: true } }
      ],
      depends_on_task_ids: [1]
    }
  },
  {
    display_order: 3,
    title_en: "Create organization contact",
    title_et: "Loo ettevõtte kontakt",
    body_en: "Create an organization contact that will be used for domain registration. Fill all required fields with correctly formatted data and indicate field types where applicable. Make sure the registrant email address is deliverable to you.",
    body_et: "Loo ettevõtte kontakt, mis on vajalik domeeni registreerimiseks. Kõik nõutud väljad tuleb täita õigel kujul ning vajadusel märgi väljade tüübid korrektselt. Veendu, et registreerija e-posti aadress oleks sulle kättesaadav.",
    validator: {
      klass: "SingleContactValidator",
      config: {
        expected_type: "org",
        input_key: "org_contact_id",
        window_minutes: 15
      },
      input_fields: [
        { name: "org_contact_id", label_en: "Organization contact ID", label_et: "Ettevõtte kontakti ID", required: true }
      ],
      depends_on_task_ids: []
    }
  },
  {
    display_order: 4,
    title_en: "Register domain for organization contact",
    title_et: "Registreeri domeen ettevõttele",
    body_en: "Using the organization contact from Task 3, register the domain {{domain2}} for 2 years.",
    body_et: "Kasuta 3. ülesandes loodud ettevõtte kontakti ja registreeri domeen {{domain2}} 2 aastaks.",
    validator: {
      klass: "RegisterSingleDomainValidator",
      config: {
        domain_template: "{{domain2}}",
        period: "2y",
        registrant_var: "org_contact_id"
      },
      input_fields: [],
      allocators: [],
      depends_on_task_ids: [1, 3]
    }
  },
  {
    display_order: 5,
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
      ],
      depends_on_task_ids: [2]
    }
  },
  {
    display_order: 6,
    title_en: "Registrar change for two domains",
    title_et: "Registripidaja muutus kahele domeenile",
    body_en: "Transfer domains {{ xfer_domain1 }} and {{ xfer_domain2 }} from another registrar.\nTransfer codes:\n- {{ xfer_domain1 }}: {{ xfer_code1 }}\n- {{ xfer_domain2 }}: {{ xfer_code2 }}",
    body_et: "Kanna domeenid {{ xfer_domain1 }} ja {{ xfer_domain2 }} teiselt registripidajalt üle.\nÜlekandekoodid:\n- {{ xfer_domain1 }}: {{ xfer_code1 }}\n- {{ xfer_domain2 }}: {{ xfer_code2 }}",
    validator: {
      klass: "TransferDomainsValidator",
      config: {
        domains: ["{{xfer_domain1}}", "{{xfer_domain2}}"]
      },
      input_fields: [],
      allocators: [
        { name: "domain_transfer_seed", config: { count: 2, use_faker: true } }
      ],
      depends_on_task_ids: []
    }
  },
  {
    display_order: 7,
    title_en: "Domain renewal",
    title_et: "Domeeni pikendamine",
    body_en: "Renew domain {{domain1}} for 5 years.",
    body_et: "Pikenda domeeni {{domain1}} 5 aastaks.",
    validator: {
      klass: "RenewDomainValidator",
      config: { domain: "{{domain1}}", years: 6 },
      input_fields: [],
      allocators: [],
      depends_on_task_ids: [2]
    }
  },
  {
    display_order: 8,
    title_en: "Update registrant email on first transferred domain",
    title_et: "Uuenda esimese ülekande-domeeni registreerija e-posti",
    body_en: "Change the registrant email address of {{xfer_domain1}} so that it matches your own login email.",
    body_et: "Muuda domeeni {{xfer_domain1}} registreerija e-posti nii, et see oleks sinu enda sisselogimise e-posti aadress ja oleks sulle kättesaadav.",
    validator: {
      klass: "RegistrantEmailMatchesUserValidator",
      config: {
        domain_template: "{{xfer_domain1}}"
      },
      input_fields: [],
      allocators: [],
      depends_on_task_ids: [6]
    }
  },
  {
    display_order: 9,
    title_en: "Fix broken domain",
    title_et: "Paranda katkine domeen",
    body_en: "Fix the broken domain {{xfer_domain2}}. In the test environment you can see warnings that the registrant’s email address, although it looks syntactically correct, is not working and has caused domain restrictions to be applied. The domain currently has the following statuses: serverForceDelete, serverRenewProhibited and serverTransferProhibited.\n\nUpdate the registrant’s email address so that it matches your own login email and is deliverable to you. After the fix, these restrictions must be removed from the domain – it must no longer be in force delete state and renew/transfer restrictions must be cleared.",
    body_et: "Paranda katkine domeen {{xfer_domain2}}. Testikeskkonnas näed selle domeeni juures hoiatust, et registreerija e‑posti aadress, kuigi visuaalselt korrektne, ei tööta ning domeenile on seetõttu lisatud piirangud. Domeenil on hetkel järgmised staatused: serverForceDelete, serverRenewProhibited ja serverTransferProhibited.\n\nUuenda registreerija e‑posti aadress selliseks, et see oleks sinu enda sisselogimise e‑posti aadress ja sulle reaalselt kättesaadav. Pärast parandamist peavad need piirangud domeenilt kaduma – domeen ei tohi enam olla force delete staatuses ning renew/transfer piirangud peavad olema eemaldatud.",
    validator: {
      klass: "FixBrokenEmailValidator",
      config: {
        domain_template: "{{xfer_domain2}}"
      },
      input_fields: [],
      allocators: [],
      depends_on_task_ids: [6]
    }
  },
  {
    display_order: 10,
    title_en: "Align first transferred domain registrant with your domain",
    title_et: "Joonda esimese ülekande-domeeni registreerija sinu domeeniga",
    body_en: "Change the registrant of {{xfer_domain1}} so that it matches the registrant of {{domain1}} (the domain you registered in task 2).",
    body_et: "Muuda domeeni {{xfer_domain1}} registreerija samaks domeeni {{domain1}} registreerijaga (domeen, mida registreerisid 2. ülesandes).",
    validator: {
      klass: "ChangeRegistrantValidator",
      config: {
        xfer_domain: "{{xfer_domain1}}",
        source_domain: "{{domain1}}"
      },
      input_fields: [],
      depends_on_task_ids: [2, 6]
    }
  },
  {
    display_order: 11,
    title_en: "Registrant change without verified=yes",
    title_et: "Registreerija vahetus ilma verified=yes",
    body_en: "Change the registrant of {{xfer_domain1}} to match the registrant of {{domain1}} using email confirmation (without verified=yes).",
    body_et: "Vaheta domeeni {{xfer_domain1}} registreerija samaks domeeni {{domain1}} registreerijaga, kasutades e-posti kinnitust (ilma verified=yes kasutamata).",
    validator: {
      klass: "ChangeRegistrantWithMethodValidator",
      config: {
        source_domain: "{{domain1}}",
        target_domain: "{{xfer_domain1}}",
        expected_method: "email_confirmation"
      },
      input_fields: [],
      depends_on_task_ids: [2, 6]
    }
  },
  {
    display_order: 12,
    title_en: "Registrant change with verified=yes",
    title_et: "Registreerija vahetus verified=yes abil",
    body_en: "Change the registrant of {{xfer_domain2}} to match the registrant of {{domain1}} using the verified=yes option.",
    body_et: "Vaheta domeeni {{xfer_domain2}} registreerija samaks domeeni {{domain1}} registreerijaga, kasutades verified=yes valikut.",
    validator: {
      klass: "ChangeRegistrantWithMethodValidator",
      config: {
        source_domain: "{{domain1}}",
        target_domain: "{{xfer_domain2}}",
        expected_method: "verified"
      },
      input_fields: [],
      depends_on_task_ids: [2, 6]
    }
  },
  {
    display_order: 13,
    title_en: "Delete second transferred domain",
    title_et: "Kustuta teine ülekande-domeen",
    body_en: "Delete the domain {{xfer_domain2}} using the verified=yes option so that it immediately enters pendingDelete status.",
    body_et: "Kustuta domeen {{xfer_domain2}}, kasutades verified=yes valikut, nii et see läheks kohe pendingDelete staatusesse.",
    validator: {
      klass: "DeleteDomainVerifiedValidator",
      config: {
        domain: "{{xfer_domain2}}"
      },
      input_fields: [],
      depends_on_task_ids: [12]
    }
  },
  {
    display_order: 14,
    title_en: "Add clientHold to first transferred domain",
    title_et: "Lisa clientHold esimesele ülekande-domeenile",
    body_en: "The domain {{xfer_domain1}} should have clientHold status. Add it using the XML console in the registrar portal (domain update, add client hold).",
    body_et: "Domeenil {{xfer_domain1}} peab olema clientHold staatus. Lisa see registripidaja portaali XML konsooli kaudu (domeeni uuendus, add client hold).",
    validator: {
      klass: "ClientHoldStatusValidator",
      config: {
        domain_template: "{{xfer_domain1}}",
        expect_absent: false
      },
      input_fields: [],
      depends_on_task_ids: [11]
    }
  },
  {
    display_order: 15,
    title_en: "Invoice generation",
    title_et: "Arve loomine",
    body_en: "Log into the test environment web portal and create a new invoice, then cancel it.",
    body_et: "Logi testi keskkonna veebportaali, loo uus arve ja seejärel tühista see.",
    validator: {
      klass: "CreateAndCancelInvoiceValidator",
      config: {
        window_minutes: 15
      },
      input_fields: [],
      depends_on_task_ids: []
    }
  }
]

tasks_v2.each do |task_data|
  task = PracticalTask.find_or_initialize_by(
    test_id: test_v2.id,
    display_order: task_data[:display_order]
  )

  task.assign_attributes(
    title_en: task_data[:title_en],
    title_et: task_data[:title_et],
    body_en: task_data[:body_en],
    body_et: task_data[:body_et],
    validator: task_data[:validator].to_json,
    active: true
  )

  if task.save
    puts "✓ Created/Updated v2: #{task.title_en}"
  else
    puts "✗ Failed v2: #{task.title_en} - #{task.errors.full_messages.join(', ')}"
  end
end

task5 = test_v2.practical_tasks.find_by(display_order: 5)
if task5
  task5.update!(
    body_en: "Add/update nameservers of the domains created in the previous step.\nFor {{domain1}}: \n- Hostname {{ns1_1}}\nFor {{domain2}}:\n- Hostname {{ns2_1}}",
    body_et: "Lisa/uuda nimeserverid domeenidele, mis on loodud eelmises sammos.\n{{domain1}}:\n- Hostname {{ns1_1}}\n{{domain2}}:\n- Hostname {{ns2_1}}",
    validator: {
      klass: 'UpdateNameserversValidator',
      config: { nameservers: { '{{domain1}}' => '{{ns1_1}}', '{{domain2}}' => '{{ns2_1}}' } },
      input_fields: [],
      allocators: [{ name: 'nameservers', config: { count: 1, use_faker: true } }],
      depends_on_task_ids: [2]
    }.to_json
  )
  puts "✓ Task 5 (nameserver management) body and validator fixed"
end

puts "Practical tasks v2 seeding completed!"

