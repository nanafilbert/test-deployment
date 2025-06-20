/*
 * Portfolio Website JavaScript
 * Author: Filbert Nana Blessing
 */

document.addEventListener('DOMContentLoaded', function() {
  'use strict';

  /**
   * Easy selector helper function
   */
  const select = (el, all = false) => {
    el = el.trim();
    if (all) {
      return [...document.querySelectorAll(el)];
    } else {
      return document.querySelector(el);
    }
  };

  /**
   * Easy event listener function
   */
  const on = (type, el, listener, all = false) => {
    let selectEl = select(el, all);
    if (selectEl) {
      if (all) {
        selectEl.forEach(e => e.addEventListener(type, listener));
      } else {
        selectEl.addEventListener(type, listener);
      }
    }
  };

  /**
   * Easy on scroll event listener 
   */
  const onscroll = (el, listener) => {
    el.addEventListener('scroll', listener);
  };

  /**
   * Navbar links active state on scroll
   */
  let navbarlinks = select('#navbarNav .nav-link', true);
  const navbarlinksActive = () => {
    let position = window.scrollY + 200;
    navbarlinks.forEach(navbarlink => {
      if (!navbarlink.hash) return;
      let section = select(navbarlink.hash);
      if (!section) return;
      if (position >= section.offsetTop && position <= (section.offsetTop + section.offsetHeight)) {
        navbarlink.classList.add('active');
      } else {
        navbarlink.classList.remove('active');
      }
    });
  };
  window.addEventListener('load', navbarlinksActive);
  onscroll(document, navbarlinksActive);

  /**
   * Scrolls to an element with header offset
   */
  const scrollto = (el) => {
    let elementPos = select(el).offsetTop;
    window.scrollTo({
      top: elementPos - 70,
      behavior: 'smooth'
    });
  };

  /**
   * Toggle .navbar-scrolled class when page is scrolled
   */
  let selectHeader = select('.navbar');
  if (selectHeader) {
    const headerScrolled = () => {
      if (window.scrollY > 100) {
        selectHeader.classList.add('navbar-scrolled');
      } else {
        selectHeader.classList.remove('navbar-scrolled');
      }
    };
    window.addEventListener('load', headerScrolled);
    onscroll(document, headerScrolled);
  }

  /**
   * Back to top button
   */
  let backtotop = select('.back-to-top');
  if (backtotop) {
    const toggleBacktotop = () => {
      if (window.scrollY > 100) {
        backtotop.classList.add('active');
      } else {
        backtotop.classList.remove('active');
      }
    };
    window.addEventListener('load', toggleBacktotop);
    onscroll(document, toggleBacktotop);
  }

  /**
   * Mobile nav toggle
   */
  on('click', '.navbar-toggler', function(e) {
    select('body').classList.toggle('mobile-nav-active');
    this.classList.toggle('bi-list');
    this.classList.toggle('bi-x');
  });

  /**
   * Scroll with offset on links with a class name .scrollto
   */
  on('click', '.scrollto', function(e) {
    if (select(this.hash)) {
      e.preventDefault();
      scrollto(this.hash);
    }
  }, true);

  /**
   * Scroll with offset on page load with hash links in the url
   */
  window.addEventListener('load', () => {
    if (window.location.hash) {
      if (select(window.location.hash)) {
        scrollto(window.location.hash);
      }
    }
  });

  /**
   * Skills animation
   */
  let skilsContent = select('.skills-content');
  if (skilsContent) {
    new Waypoint({
      element: skilsContent,
      offset: '80%',
      handler: function(direction) {
        let progress = select('.progress .progress-bar', true);
        progress.forEach((el) => {
          el.style.width = el.getAttribute('aria-valuenow') + '%';
        });
      }
    });
  }

  /**
   * Animation on scroll
   */
  window.addEventListener('load', () => {
    AOS.init({
      duration: 1000,
      easing: 'ease-in-out',
      once: true,
      mirror: false
    });
  });

  /**
   * Initialize tooltips
   */
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  /**
   * Contact form validation
   */
  const validateEmail = (email) => {
    return String(email)
      .toLowerCase()
      .match(/^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/);
  };

  const contactForm = document.getElementById('contactForm');
  if (contactForm) {
    contactForm.addEventListener('submit', function(e) {
      e.preventDefault();
      
      // Simple form validation
      let name = document.getElementById('name').value;
      let email = document.getElementById('email').value;
      let message = document.getElementById('message').value;
      let isValid = true;
      
      if (name === '') {
        document.getElementById('name').classList.add('is-invalid');
        isValid = false;
      } else {
        document.getElementById('name').classList.remove('is-invalid');
      }
      
      if (email === '' || !validateEmail(email)) {
        document.getElementById('email').classList.add('is-invalid');
        isValid = false;
      } else {
        document.getElementById('email').classList.remove('is-invalid');
      }
      
      if (message === '') {
        document.getElementById('message').classList.add('is-invalid');
        isValid = false;
      } else {
        document.getElementById('message').classList.remove('is-invalid');
      }
      
      if (isValid) {
        // In a real application, you would send the form data to a server here
        alert('Thank you for your message! This form is currently under construction.');
        contactForm.reset();
      }
    });
  }

  /**
   * Modal contact form
   */
  const modalContactBtn = document.getElementById('sendModalMessage');
  if (modalContactBtn) {
    modalContactBtn.addEventListener('click', function() {
      let name = document.getElementById('modalName').value;
      let email = document.getElementById('modalEmail').value;
      let message = document.getElementById('modalMessage').value;
      let isValid = true;
      
      if (name === '') {
        document.getElementById('modalName').classList.add('is-invalid');
        isValid = false;
      } else {
        document.getElementById('modalName').classList.remove('is-invalid');
      }
      
      if (email === '' || !validateEmail(email)) {
        document.getElementById('modalEmail').classList.add('is-invalid');
        isValid = false;
      } else {
        document.getElementById('modalEmail').classList.remove('is-invalid');
      }
      
      if (message === '') {
        document.getElementById('modalMessage').classList.add('is-invalid');
        isValid = false;
      } else {
        document.getElementById('modalMessage').classList.remove('is-invalid');
      }
      
      if (isValid) {
        // In a real application, you would send the form data to a server here
        alert('Thank you for your message! This form is currently under construction.');
        document.getElementById('contactModal').querySelector('form').reset();
        bootstrap.Modal.getInstance(document.getElementById('contactModal')).hide();
      }
    });
  }
});