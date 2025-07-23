import Choices from "choices.js";

export default class Select {
  constructor(target, options = {}) {
    this.element = target;
    this.options = options;
    this.choices = null;
    this.init();
  }
    
  init() {
    this.setOptions();
    let className = this.element.className;
    this.choices = new Choices(this.element, { ...this.options });
    this.handleContactDynamicSelect(className);
    this.handleIdentTypeSelect(this.element.id);
  }

  findGetParameter(parameterName) {
    var result = null, tmp = [];
    var items = location.search.substr(1).split('&');
    for (var index = 0; index < items.length; index++) {
      tmp = items[index].split('=');
      if (decodeURIComponent(tmp[0]) === parameterName) result = decodeURIComponent(tmp[1]);
    }
    return result;
  }

  withPlaceholder(data) {
    data.unshift({value: '', label: ' ', selected: false});
    return data;
  }

  setOptions() {
    this.options['itemSelectText'] = this.element.getAttribute('itemSelectText');
    this.options['shouldSort'] = false;
    this.options['silent'] = true;
    this.options['allowHTML'] = true;
    this.options['noChoicesText'] = this.element.getAttribute('noChoicesText');
  }

  handleContactDynamicSelect(className) {
    if (className === 'contact_dynamic_select') {
      let host = window.location.protocol + '//' + window.location.host;
      this.element.addEventListener('search', async (e) => {
        let query = e.detail.value;
        await fetch(host + '/contacts/search?query=' + query)
        .then(res => res.json())
        .then(data => this.choices.setChoices(this.withPlaceholder(data), 'value', 'label', true));
      });
      let param = this.findGetParameter('search[registrant_code_eq]');
      if (param != null && param != '') {
        fetch(host + '/contacts/search/' + param)
        .then(res => res.json())
        .then(data => this.choices.setChoices(this.withPlaceholder(data), 'value', 'label', true));
      }
    }
  }

  handleIdentTypeSelect(id) {
    if (id === 'ident_type_select') {
      this.element.addEventListener('choice', function(e) {
        let value = e.detail.choice.value;
        let birthday_info_el = document.getElementById('insert_birthday_info');
        let display = ((value === 'birthday') ? 'block' : 'none');
        birthday_info_el.style.display = display;
      }, false );
    }
  }
}
