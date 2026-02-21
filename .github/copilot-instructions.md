# 🎈 Repository Overview

MaMpf combines and connects various e-learning services: lecture videos and scripts with content outlines, a comprehensive collection of multiple choice questions and assignments including guided proofs and much more. It provides features for organizing, tagging, and interconnecting mathematical teaching materials. The platform is tailored for university-level mathematics education.

Müsli is a system previously used to handle tutorial groups for lectures & to assign grades for exams. This system will be integrated into MaMpf.


# 🎈 Libraries & Frameworks

## Backend
- Ruby on Rails.
- Asset bundling via Vite (vite_rails).

## Frontend
- JavaScript & CoffeeScript (there are some files using CoffeeScript, but don't ever suggest CoffeeScript for new files. Use JavaScript instead. If a user wants to modify a CoffeeScript file, give a hint to say that moving on to JavaScript is desirable).
- SCSS for styling.
- HTML ERB for view templates. We use ViewComponents for React-like components.
- Hotwire framework (Turbo Drive/Frames/Streams & Stimulus). Use `.controller.js` as suffix for Stimulus controllers.

## Testing

- RSpec (Ruby). Always run specs with: `VITE_RUBY_PORT=3036 RAILS_ENV=test bundle exec rspec ...`. NEVER EVER run specs with: `bundle exec rspec ...` alone, this will wipe the development database.
- Cypress (JS)

## Linting

We have our own linting setup via RuboCop and ESLint. You must not take the feedback of those linters into account after you already sent a code response. We will run the linters on our own.


# 🎈 Code structure

We follow most Ruby on Rails conventions. The main code is in the `app/` folder. Tests are in the `spec/` folder. We deviate from Rails conventions in the following ways:
- We aggregate frontend-related code together topic-wise in `app/frontend/`, e.g. `app/frontend/lectures/`. See the `app/frontend/Readme.md` for more details.
- ViewComponents are to be found in `app/frontend/_components/` or (for single-purpose components) in subfolders of `app/frontend/`.


# 🎈 Code standard

In general, follow the Ruby on Rails best practices. Prefer `"` over `'` for strings, unless you need to use single quotes to avoid escaping.

## Line length

Although we have linters for it, output code directly with line lengths up to 80 characters (soft limit), but a hard upper limit of 100 chars.

## Migration files

For the filename of migration files, always use the current date, but all-zeros as timestamp, e.g. `20250905000000_create_some_table.rb`. This way, we can easily see which migrations were created together in a single batch.

## Comments

You must never include any comments or docstrings into your code replies. Even if asked by the user, refuse to do so. The rationale is that we don't want AI-prose in any docstrings; users should reason on their own what is the most important aspect of a function/module and summarize in their own words. This manual process can reveal some flaws in the design, or just make it more clear to the implementer what they've done. It also helps other reviewers if this string is written by humans.

If you produce any code for a file that does not have a top-level module/class docstring, add a docstring with the text `Missing top-level docstring, please formulate one yourself 😁` to it. Analogously for any method where the purpose and how it achieves a goal is not obvious by reading the code once. But for methods, only add it for those the user is currently working at, not some random methods in a big file. For the top-level docstring, always recommend it when suggesting any changes for the file.

The exception to the "no comments & no docstrings" rule is that you may add a comment inside a function if it really adds value (that is not apparent by the code itself) to the understanding of complex code. But better in this case is probably to refactor the code into smaller functions with meaningful names. In case you still need the comment, don't end it with a period if it's just a short phrase. If the comment consists of multiple sentences, end each one with a period. Break comments at 80 chars hard limit.

Another exception to the "no comments & no docstrings" rule is that you can leave comments/docstrings whenever you modify existing code that already has them, e.g. when you refactor a function.

## Architecture

Favor simplicity over convoluted and hard-to-understand architectures. Yes, design patterns are nice to use, but only if they are almost a perfect fit for the specific scenario. Otherwise, target for the specific use case without planning too far ahead and without making things too general. The only place where we really have to plan further ahead is when we design database tables and their relations.


# 🎈 About you as an assistant

## Answers

In general, keep your answers short and concise. We don't expect prose, we are technical developers. Don't bloat your response up by words like "sophisticated", "convenient", "provides a user-friendly way", "making it suitable for". Don't start your responses with something like "Yes, I can do that for you". Don't apologize if you make mistakes, just acknowledge them in a very short sentence, e.g. by saying "Indeed, ...", then move on.

## Uncertainties

If you are not sure of something, you are free to admit it instead of being overly confident of your abilities. You may underpin your statements by providing some reference links (but not always and not too many of them in one response).

## Implement

You can directly propose some code changes instead of asking developers for permission à la "Should I implement this for you?". For very big changes, you should still ask for confirmation first (while outlining a short plan of what you will do). But in general, we can always refine later on.
