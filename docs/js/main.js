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

  /* THEME FUNCTION */
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
  }// end applyTheme();

  // load saved theme or default to night
  var saved = null;
  try{ saved = localStorage.getItem(THEME_KEY); }catch(e){/* ignore storage errors */}
  var theme = (saved === 'day' ? 'day' : 'night');
  applyTheme(theme);

  /* THEME TOGGLE CHECK */
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

  
  /* Contact carousel (center card zoom + details, circular) */
(function () {
  const root = document.getElementById('contact-carousel');
  if (!root) return;

  const track = root.querySelector('.carousel-track');
  const prevBtn = root.querySelector('.carousel-prev');
  const nextBtn = root.querySelector('.carousel-next');

  // Cache cards as an array (DOM order matters for visual order)
  let cards = Array.from(track.children);
  const N = cards.length;           // assume 5
  const CENTER = 2;                 // 0-based center position
  const CARD_W = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--card-w')) || 220;
  const GAP = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--card-gap')) || 16;
  const STEP = CARD_W + GAP;        // how far the track moves per click

  // We keep a "start" index: the card shown at position 0 (far left).
  // The visible order is [start, start+1, ... start+N-1] mod N.
  // Default focused index should be CENTER (2) and Ish should be located there by default.
  // Find Ish (data-id="ishit") and rotate so Ish appears at CENTER.
  let start = 0;
  const ishIndex = cards.findIndex(el => el.dataset && el.dataset.id === 'ishit');
  if (ishIndex >= 0) {
    start = (ishIndex - CENTER + N) % N;
  }

  // Helpers
  function setActive() {
    // Remove & set .is-active on the DOM child that is currently at CENTER
    cards.forEach(el => el.classList.remove('is-active'));
    const active = track.children[CENTER];
    if (active) active.classList.add('is-active');
  }

  // Rebuild DOM children in the current visual order
  function reorderDOM() {
    const order = [];
    for (let i = 0; i < N; i++) {
      order.push(cards[(start + i) % N]);
    }
    order.forEach(node => track.appendChild(node));
    
    setActive();
  }
  /* SLIDE ANIMATION FUNCTION */
  // Animate one step - reorder, then slide into palce
  let animating = false;
  function slideOne(direction) {
    // direction: +1 = move right (content slides left), -1 = move left
    if (animating) return;
    animating = true;

    start = (start + (direction > 0 ? 1 : -1) + N) % N; // update logical start

    reorderDOM(); // put DOM into new order

    // Start offset so there's card "offscreen"
    const from = direction > 0 ? STEP : -STEP;
    track.style.transition = 'none';
    track.style.transform = `translateX(${from}px)`;

    void track.offsetWidth; // force reflow

    // animate back to 0
    track.style.transition = `transform var(--slide-ms, 450ms) ease`;
    track.style.transform = 'translateX(0px)';

    const done = () => {
      track.removeEventListener('transitionend', done);
      track.style.transition = 'none';
      track.style.transform = 'translateX(0px)';
      animating = false;
    };
    track.addEventListener('transitionend', done, { once: true });

  }//end slideOne();

  function moveSteps(steps) {
    // steps > 0 => move right; steps < 0 => move left
    const dir = Math.sign(steps);
    const count = Math.abs(steps);
    if (count === 0) return;
    let i = 0;
    const next = () => {
      if (i++ >= count) return;
      slideOne(dir);
      // chain next slide after each ends
      const wait = () => {
        if (!animating) {
          if (i < count) next();
        } else {
          requestAnimationFrame(wait);
        }
      };
      wait();
    };
    next();
  }

  // Click handlers for prev/next
  prevBtn?.addEventListener('click', () => moveSteps(-1));
  nextBtn?.addEventListener('click', () => moveSteps(+1));

  // Clicking a card should move it to CENTER using the shortest path
  track.addEventListener('click', (e) => {
    const card = e.target.closest('.person');
    if (!card) return;
    const pos = Array.from(track.children).indexOf(card);  // 0..N-1
    if (pos === -1) return;

    // distance to move card to CENTER (positive => move right)
    let delta = pos - CENTER; // how many right moves
    // Wrap to shortest path
    if (delta > N / 2) delta -= N;
    if (delta < -N / 2) delta += N;
    moveSteps(delta);
  });

  // Initial state
  reorderDOM();
})();


    // --- Auth page toggle + backend wiring (signup default) ---
  (function () {
    var authCard = document.getElementById("auth-card");
    if (!authCard) return;

    var showLoginButtons = Array.from(
      document.querySelectorAll(".js-show-login")
    );
    var showSignupButtons = Array.from(
      document.querySelectorAll(".js-show-signup")
    );
    var signInBtn = document.getElementById("sign-in-btn");
    var createAccountBtn = document.getElementById("create-account-btn");

    // 👉 Set this to your real worker URL (no trailing slash)
    var WORKER_BASE_URL = "https://rentswipe-auth.rentswipe.workers.dev";

    function showLogin() {
      authCard.classList.add("auth-mode-login");
      var panelLogin = document.getElementById("panel-login");
      var panelSignup = document.getElementById("panel-signup");
      if (panelLogin) panelLogin.setAttribute("aria-hidden", "false");
      if (panelSignup) panelSignup.setAttribute("aria-hidden", "true");
      var loginEmail = document.getElementById("login-email");
      if (loginEmail) loginEmail.focus();
    }

    function showSignup() {
      authCard.classList.remove("auth-mode-login");
      var panelLogin = document.getElementById("panel-login");
      var panelSignup = document.getElementById("panel-signup");
      if (panelLogin) panelLogin.setAttribute("aria-hidden", "true");
      if (panelSignup) panelSignup.setAttribute("aria-hidden", "false");
      var nameInput = document.getElementById("fullname");
      if (nameInput) nameInput.focus();
    }

    // Toggle buttons/links
    showLoginButtons.forEach(function (btn) {
      btn.addEventListener("click", showLogin);
      btn.addEventListener("keydown", function (e) {
        if (e.key === "Enter") showLogin();
      });
    });
    showSignupButtons.forEach(function (btn) {
      btn.addEventListener("click", showSignup);
      btn.addEventListener("keydown", function (e) {
        if (e.key === "Enter") showSignup();
      });
    });

    // === Backend calls ===

    async function signup() {
      var fullName = (document.getElementById("fullname") || {}).value || "";
      var email = (document.getElementById("signup-email") || {}).value || "";
      var password =
        (document.getElementById("signup-password") || {}).value || "";
      fullName = fullName.trim();
      email = email.trim();
      password = password.trim();

      var accountTypeInput = document.querySelector(
        'input[name="accountType"]:checked'
      );
      var accountType = accountTypeInput ? accountTypeInput.value : null;

      if (!fullName || !email || !password || !accountType) {
        alert("Please fill out all fields and select an account type.");
        return;
      }

      if (!WORKER_BASE_URL) {
        console.error("WORKER_BASE_URL is not set");
        return;
      }

      if (createAccountBtn) {
        createAccountBtn.disabled = true;
        createAccountBtn.textContent = "Creating...";
      }

      try {
        const res = await fetch(WORKER_BASE_URL + "/api/signup", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            fullName: fullName,
            email: email,
            password: password,
            accountType: accountType,
          }),
        });

        let data = {};
        try {
          data = await res.json();
        } catch (e) {}

        if (!res.ok || !data.ok) {
          alert(data.error || "Signup failed. Please try again.");
          if (createAccountBtn) {
            createAccountBtn.disabled = false;
            createAccountBtn.textContent = "Create account";
          }
          return;
        }

        window.location.href = "home.html"; 
      } catch (err) {
        console.error("Signup error:", err);
        alert("Something went wrong. Please try again.");
        if (createAccountBtn) {
          createAccountBtn.disabled = false;
          createAccountBtn.textContent = "Create account";
        }
      }
    }

    async function login() {
      var email = (document.getElementById("login-email") || {}).value || "";
      var password =
        (document.getElementById("login-password") || {}).value || "";
      email = email.trim();
      password = password.trim();

      if (!email || !password) {
        alert("Please enter your email and password.");
        return;
      }

      if (!WORKER_BASE_URL) {
        console.error("WORKER_BASE_URL is not set");
        return;
      }

      if (signInBtn) {
        signInBtn.disabled = true;
        signInBtn.textContent = "Signing in...";
      }

      try {
        const res = await fetch(WORKER_BASE_URL + "/api/login", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email: email, password: password }),
        });

        let data = {};
        try {
          data = await res.json();
        } catch (e) {}

        if (!res.ok || !data.ok) {
          alert(data.error || "Login failed. Please try again.");
          if (signInBtn) {
            signInBtn.disabled = false;
            signInBtn.textContent = "Sign in";
          }
          return;
        }

        window.location.href = "home.html"; 
      } catch (err) {
        console.error("Login error:", err);
        alert("Something went wrong. Please try again.");
        if (signInBtn) {
          signInBtn.disabled = false;
          signInBtn.textContent = "Sign in";
        }
      }
    }

    if (signInBtn) {
      signInBtn.addEventListener("click", login);
    }
    if (createAccountBtn) {
      createAccountBtn.addEventListener("click", signup);
    }

    // Default view
    showSignup();
  })();
}); // end DOMContentLoaded
