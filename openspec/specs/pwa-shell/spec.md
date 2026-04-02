# pwa-shell Specification

## Purpose

The pwa-shell capability defines the installable, offline-capable browser shell that will host the chat experience, present sources, and run the WASM knowledge interface without requiring a bespoke native application.

## Requirements

### Requirement: Provide an installable browser shell

The system SHALL provide a PWA shell that can be served as static assets and installed in modern browsers.

#### Scenario: Open the static site as an installable app

- GIVEN the youaskm3 site is published through GitHub Pages
- WHEN a user visits it in a supported browser
- THEN the browser can recognize it as an installable PWA shell

### Requirement: Present knowledge conversations with source context

The system SHALL reserve UI surfaces for chat responses and source attribution so the future interface can explain how results were derived.

#### Scenario: Render a source-backed answer shell

- GIVEN the chat interface returns a knowledge answer with sources
- WHEN the PWA shell renders the response
- THEN the UI can display both the answer and its source references
