// Interactive behavior: mobile nav toggle, theme toggle (with persistence), and dynamic year
document.addEventListener('DOMContentLoaded', function(){
  var navToggle = document.getElementById('nav-toggle');
  var nav = document.getElementById('site-nav');
  if(navToggle && nav){
    navToggle.addEventListener('click', function(){
      var expanded = this.getAttribute('aria-expanded') === 'true';
      this.setAttribute('aria-expanded', String(!expanded));
      var visible = !expanded;
      // flip aria-hidden on nav to match visible state (CSS shows nav when aria-hidden="false")
      nav.setAttribute('aria-hidden', String(!visible));
    });
  }

  // Theme toggle: persist choice in localStorage. Default to 'night'.
  var THEME_KEY = 'rentswipe-theme';
  var themeToggle = document.getElementById('theme-toggle');

  function applyTheme(theme){
    // theme is 'day' or 'night'
    if(theme === 'day'){
      document.documentElement.setAttribute('data-theme','day');
      if(themeToggle){
        themeToggle.classList.add('is-day');
        themeToggle.setAttribute('aria-pressed','true');
        themeToggle.setAttribute('aria-label','Switch to night mode');
      }
    } else {
      document.documentElement.removeAttribute('data-theme');
      if(themeToggle){
        themeToggle.classList.remove('is-day');
        themeToggle.setAttribute('aria-pressed','false');
        themeToggle.setAttribute('aria-label','Switch to day mode');
      }
    }
  }

  // load saved theme or default to night
  var saved = null;
  try{ saved = localStorage.getItem(THEME_KEY); }catch(e){/* ignore storage errors */}
  var theme = (saved === 'day' ? 'day' : 'night');
  applyTheme(theme);

  if(themeToggle){
    themeToggle.addEventListener('click', function(){
      var current = document.documentElement.getAttribute('data-theme') === 'day' ? 'day' : 'night';
      var next = current === 'day' ? 'night' : 'day';
      applyTheme(next);
      try{ localStorage.setItem(THEME_KEY, next); }catch(e){/* ignore */}
    });
  }

  // set current year in footer
  var y = new Date().getFullYear();
  var yearEl = document.getElementById('year');
  if(yearEl) yearEl.textContent = y;
});
