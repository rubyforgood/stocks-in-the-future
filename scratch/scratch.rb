<!DOCTYPE html>
<html>
  <head>
    <title>StocksInTheFuture</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>
  </head>
  <body>
    <p class="notice"><%= notice %></p>
    <p class="alert"><%= alert %></p>

    <nav class="nav-container">
      <div class="nav-wrapper">
        <div class="absolute inset-y-0 left-0 flex items-center sm:hidden">
          <!-- Mobile menu button -->
          <button type="button" class="nav-mobile-button" aria-controls="mobile-menu" aria-expanded="false">
            <span class="absolute -inset-0.5"></span>
            <span class="sr-only">Open main menu</span>
            <!--
              Icon when menu is closed.

              Menu open: "hidden", Menu closed: "block"
            -->
            <svg class="block size-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" data-slot="icon">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
            </svg>
            <!--
              Icon when menu is open.

              Menu open: "block", Menu closed: "hidden"
            -->
            <svg class="hidden size-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true" data-slot="icon">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div class="nav-main">
          <div class="nav-logo-wrapper">
            <%= image_tag "SITF-caponly-Logo.svg", class: "h-8 w-auto", alt: "Stocks in The Future" %>
          </div>
          <div class="nav-links-wrapper">
            <a href="<%= classrooms_path %>"
               class="nav-link <%= current_page?(classrooms_path) ? 'nav-link-active' : 'nav-link-inactive' %>">
              My Classes
            </a>
            <a href="<%= stocks_path %>"
               class="nav-link <%= current_page?(stocks_path) ? 'nav-link-active' : 'nav-link-inactive' %>">
              Stocks
            </a>
            <a href="<%= portfolio_path(current_user.portfolio) %>"
               class="nav-link <%= current_page?(portfolio_path(current_user.portfolio)) ? 'nav-link-active' : 'nav-link-inactive' %>">
              My Portfolio
            </a>
          </div>
        </div>
        <div class="nav-user-section">
          <div class="nav-user-menu">
            <div class="nav-user-links">
              <a href="#" class="nav-user-link" role="menuitem" tabindex="-1" id="user-menu-item-0">Your Profile</a>
              <a href="#" class="nav-user-link" role="menuitem" tabindex="-1" id="user-menu-item-2">Sign out</a>
              <% if current_user&.admin? %>
                <a href="<#= admin_root_path%>" class="nav-user-link" role="menuitem" tabindex="-1" id="user-menu-item-3">Admins</a>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </nav>
    <%= yield %>
  </body>
</html>





app/assets/stylesheets/application.tailwind.css
@import 'shadcn.css';
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer components {
  .nav-container {
    @apply mx-auto px-2 sm:px-6 lg:px-8;
  }

  .nav-wrapper {
    @apply relative flex h-16 justify-between;
  }

  .nav-mobile-button {
    @apply relative inline-flex items-center justify-center rounded-md p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500 focus:ring-2 focus:ring-indigo-500 focus:outline-hidden focus:ring-inset;
  }

  .nav-main {
    @apply flex flex-1 items-center justify-start sm:items-stretch sm:justify-start;
  }

  .nav-logo-wrapper {
    @apply flex shrink-0 items-center;
  }

  .nav-links-wrapper {
    @apply hidden sm:ml-6 sm:flex sm:space-x-8;
  }

  .nav-link {
    @apply inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium;
  }

  .nav-link-active {
    @apply border-cyan-900 text-gray-900;
  }

  .nav-link-inactive {
    @apply border-transparent text-gray-500 hover:border-cyan-900 hover:text-gray-700;
  }

  .nav-user-section {
    @apply absolute inset-y-0 right-0 flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0;
  }

  .nav-user-menu {
    @apply relative ml-3;
  }

  .nav-user-links {
    @apply flex space-x-4;
  }

  .nav-user-link {
    @apply block px-4 py-2 text-sm text-gray-700;
  }
}




put first line after body in application file
    <% if notice %>
      <p class="notice"><%= notice %></p>
    <% end %>
    <% if alert %>
      <p class="alert"><%= alert %></p>
    <% end %>

and remove the alert from each of the individual views

and this to the style css file
  .notice {
    @apply bg-blue-100 border-l-4 border-blue-500 text-blue-700 p-4;
  }

  .alert {
    @apply bg-red-100 border-l-4 border-red-500 text-red-700 p-4;
  }