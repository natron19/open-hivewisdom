# Phase 1 — Branding & Customization

**Goal:** Apply HiveWisdom branding on top of the boilerplate without touching any auth, AI service, or admin panel code.

---

## 1. Environment Variables

Update `.env.example` (the committed template) and your local `.env`:

```
APP_NAME="HiveWisdom Demo"
APP_TAGLINE="Describe an initiative. See how it could fail before it actually does."
APP_DESCRIPTION="HiveWisdom Demo runs a structured premortem on any initiative you are about to commit to. Describe the initiative in five fields, click Run Premortem, and get a ranked analysis of how it could fail, what to watch for, and what to do this week."
```

These are already consumed by the layout's navbar brand, the footer, and the home page via `ENV.fetch("APP_NAME", "Open Demo Starter")`. No view changes needed for the values to propagate.

---

## 2. Accent Color

Replace the default blue accent in `app/assets/stylesheets/application.css`:

```css
:root {
  --accent: #eab308;
  --accent-hover: #ca8a04;
}
```

This applies the golden yellow throughout: primary buttons, active navbar links, and any element already using `var(--accent)`.

Add the HiveWisdom-specific custom CSS below the `:root` block:

```css
/* Avoided-truth callout */
.avoided-truth-card {
  border-left: 4px solid var(--accent);
  padding-left: 1.25rem;
}

/* Preventive action — started state */
.preventive-started {
  text-decoration: line-through;
  opacity: 0.6;
}

/* Imagined failure date banner */
.failure-date-banner {
  background: linear-gradient(135deg, rgba(234, 179, 8, 0.12), rgba(202, 138, 4, 0.06));
  border: 1px solid rgba(234, 179, 8, 0.3);
}
```

---

## 3. Navbar Links

Edit `app/views/layouts/application.html.erb`. Inside the authenticated nav section (the block that already shows the user dropdown), add the two nav links before the dropdown:

```erb
<%# Inside the <ul class="navbar-nav ..."> block, before the user dropdown %>
<% if signed_in? %>
  <li class="nav-item">
    <%= link_to "Initiatives", initiatives_path, class: "nav-link #{'active' if current_page?(initiatives_path)}" %>
  </li>
  <li class="nav-item">
    <%= link_to "New Premortem", new_initiative_path, class: "nav-link #{'active' if current_page?(new_initiative_path)}" %>
  </li>
<% end %>
```

`initiatives_path` and `new_initiative_path` will not resolve until Phase 3 routes are added. The view can be written now and will work once routes exist.

---

## 4. Home Page

Replace `app/views/home/index.html.erb` entirely:

```erb
<div class="container py-5">
  <div class="row justify-content-center">
    <div class="col-lg-7 text-center">

      <h1 class="display-5 fw-bold mb-3"><%= ENV.fetch("APP_NAME", "HiveWisdom Demo") %></h1>
      <p class="lead mb-4"><%= ENV.fetch("APP_TAGLINE", "") %></p>

      <p class="text-body-secondary mb-5">
        A premortem imagines that an initiative has already failed and asks why.
        It is one of the highest-leverage foresight practices a team can run —
        and the one most reliably skipped because it requires skill, time, and willingness
        to look at failure before it happens. This tool produces a structured first draft
        in under fifteen seconds so the team has something concrete to push back on.
      </p>

      <% if signed_in? %>
        <%= link_to "Run Your First Premortem", new_initiative_path, class: "btn btn-primary btn-lg px-5 mb-5" %>
      <% else %>
        <%= link_to "Run Your First Premortem", sign_up_path, class: "btn btn-primary btn-lg px-5 mb-5" %>
      <% end %>

      <div class="row g-4 text-start mt-2">
        <div class="col-md-4">
          <div class="p-3 border rounded h-100">
            <div class="fs-4 mb-2">📝</div>
            <h6 class="fw-semibold">Describe</h6>
            <p class="small text-body-secondary mb-0">Name the initiative and fill in five fields: what success looks like, the time horizon, where the work stands today, and who is involved.</p>
          </div>
        </div>
        <div class="col-md-4">
          <div class="p-3 border rounded h-100">
            <div class="fs-4 mb-2">💀</div>
            <h6 class="fw-semibold">Imagine Failing</h6>
            <p class="small text-body-secondary mb-0">The AI imagines the initiative has already failed and reconstructs — specifically and without softening — the five most plausible reasons why.</p>
          </div>
        </div>
        <div class="col-md-4">
          <div class="p-3 border rounded h-100">
            <div class="fs-4 mb-2">✅</div>
            <h6 class="fw-semibold">Plan This Week</h6>
            <p class="small text-body-secondary mb-0">Get a ranked list of preventive actions to take now, plus the one uncomfortable truth most premortems skip past.</p>
          </div>
        </div>
      </div>

      <p class="mt-5 text-body-secondary small">
        Open source under MIT. This is one feature from a larger foresight platform.
      </p>

    </div>
  </div>
</div>
```

---

## 5. Dashboard Page

Replace `app/views/dashboard/show.html.erb` entirely:

```erb
<div class="row g-4">

  <div class="col-md-8">
    <h5 class="mb-3">Recent Initiatives</h5>
    <% if current_user.initiatives.any? %>
      <div class="list-group">
        <% current_user.initiatives.order(created_at: :desc).limit(10).each do |initiative| %>
          <div class="list-group-item list-group-item-action d-flex justify-content-between align-items-center">
            <div>
              <%= link_to initiative.name, initiative_path(initiative), class: "fw-semibold text-decoration-none stretched-link" %>
              <div class="small text-body-secondary mt-1">
                <%= initiative.time_horizon.humanize %> horizon &middot;
                <%= pluralize(initiative.premortems.count, "premortem") %>
              </div>
            </div>
            <span class="badge bg-secondary ms-3"><%= initiative.time_horizon.gsub("_", " ") %></span>
          </div>
        <% end %>
      </div>
      <%= link_to "View all initiatives →", initiatives_path, class: "d-block mt-3 small" %>
    <% else %>
      <div class="alert alert-secondary">
        No initiatives yet. Use the card on the right to run your first premortem.
      </div>
    <% end %>
  </div>

  <div class="col-md-4">
    <div class="card border-0 bg-body-secondary h-100">
      <div class="card-body">
        <h5 class="card-title">New Initiative</h5>
        <p class="card-text text-body-secondary small mb-3">Before you start, have these ready:</p>
        <ul class="small text-body-secondary mb-4">
          <li>A one-paragraph definition of what success looks like</li>
          <li>A description of where the work stands right now</li>
          <li>Context on the team and any recent friction</li>
        </ul>
        <%= link_to "Run a Premortem", new_initiative_path, class: "btn btn-primary w-100" %>
      </div>
    </div>
  </div>

</div>
```

Note: `initiative_path`, `initiatives_path`, and `new_initiative_path` require Phase 3 routes. The dashboard will render after routes are added.

---

## Acceptance Criteria

- Home page shows HiveWisdom tagline and three icon cards
- Dashboard shows two-column layout with recent initiatives list and "New Initiative" card
- All buttons and active nav links are golden yellow
- Accent color variables are in the CSS root block
- `.env.example` has all three branding vars with HiveWisdom values
- No hardcoded app name strings in views
