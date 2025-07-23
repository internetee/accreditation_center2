export default class Header {
  constructor(selector) {
    this.target = selector;
    this.init();
  }

  init() {
    window.addEventListener('scroll', () => {
      if (window.innerWidth < 1224 && window.scrollY > 0) {
        this.target.classList.add('scrolling');
      } else {
        this.target.classList.remove('scrolling');
      }
    });

    document.querySelectorAll('[data-menu-toggle]').forEach(toggleBtn => {
      toggleBtn.addEventListener('click', () => {
        document.querySelector('body').classList.toggle('menu-open');
      });
    })
  }
}