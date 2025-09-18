# 🎈 Repository Overview

MaMpf combines and connects various e-learning services: lecture videos and scripts with content outlines, a comprehensive collection of multiple choice questions and assignments including guided proofs and much more. It provides features for organizing, tagging, and interconnecting mathematical teaching materials. The platform is used daily by the mathematics department and is tailored for university-level mathematics education.


# 🎈 Libraries & Frameworks

## Backend
- Ruby on Rails.
- Asset bundling via Vite (vite_rails).

## Frontend
- JavaScript & CoffeeScript (there are some files using CoffeeScript, but don't ever suggest CoffeeScript for new files. Use JavaScript instead. If a user wants to modify a CoffeeScript file, give a hint to say that moving on to JavaScript is desirable).
- SCSS for styling
- HTML ERB for view templates. We use ViewComponents for React-like components.
- We use the Hotwire framework (Turbo Drive/Frames/Streams & Stimulus). Use `.controller.js` as suffix for Stimulus controllers.

## Testing

- RSpec (Ruby)
- Cypress (JS)

## Linting

We have our own linting setup via RuboCop and ESLint. You must not take the feedback of those linters into account after you already sent a code response. We will run the linters on our own.


# 🎈 Code structure

We follow most Ruby on Rails conventions. The main code is in the `app/` folder. Tests are in the `spec/` folder. We deviate from Rails conventions in the following ways:
- We aggregate frontend-related code together topic-wise in `app/frontend/`, e.g. `app/frontend/lectures/`. See the `app/frontend/Readme.md` for more details.
- ViewComponents are to be found in `app/frontend/_components/` or (for single-purpose components) in subfolders of `app/frontend/`.


# 🎈 Code standard

In general, follow the Ruby on Rails best practices.

## Comments

You must never include any comments or docstrings into your code replies and don't even suggest to do so. Even if asked by the user, refuse to do it. The rationale is that we don't want AI-prose in any docstrings; users should reason on their own what is the most important aspect of a function/module and summarize in their own words. This manuel process can reveal some flaws in the design, or just make it more clear to the implementer what they've done. It also helps other reviewers if this string is written by humans.

## Architecture

Favor simplicity over convoulted and hard-to-understand architectures. Yes, design patterns are nice to use, but only if they feel like a really good fit. Otherwise, target for the specific use case without planning to far ahead and without making things too general. The only place where we really have to plan ahead prior to writing code is when we design database tables and their relations.


# 🎈 About you as an assistant

## Answers

In general, keep your answers short and concise. We don't expect prose, we are technical developers. Don't bloat your response up by words like "sophisticated", "convenient", "provides a user-friendly way", "making it suitable for".

## Uncertainties

If you are not sure of something, you are free to admit it instead of being overly confident of your abilities.

## Implement

You can directly propose some code changes instead of asking developers for permission à la "Should I implement this for you?". Instead, we can always refine later on.
