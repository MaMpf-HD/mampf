*To be considered alongside the [MaMpf Wiki](https://github.com/MaMpf-HD/mampf/wiki).*

# Frontend folder structure

Each controller has a corresponding "topic folder" with all related frontend inside, e.g. we have a `app/controllers/lecutres_controller.rb`, therefore we have an `app/frontend/lectures` folder.


## Topic folders

A topic folder (e.g. `lectures`)

- Contains (including subfolders) all frontend-related code for a specific controller (e.g. `lectures_controller.rb`). This includes views, partials, JavaScript, Stylesheets, ViewComponents etc.
- **Has subfolders corresponding to controller actions** (e.g. `edit`, `show`, `index`, `search` etc.). Shorter names may be used for folder names, e.g. `announcements` instead of `show_announcements` or `subscribe` instead of `subscribe_page`.
  - Inside these subfolders, the trinity of html, css and js should be placed together by naming convention, e.g. `index.html.erb`, `index.js`, `index.scss` for the `index` action. For partials, it can be beneficial to also include a `_` as prefix for related JS/CSS files in order to have related files displayed right next to each other in the file tree.
  [Additional files can be added as needed, e.g. `do_something_specific.js`. However, if the folder is getting too big and too messy, consider splitting it up into more folders.]
  - May contain further subfolders, consider for example `vignettes/slides/form/answer_types/`. However, deeply nesting should be avoided.
  - [for very big topics] These subfolders can also refer to "user-like boundaries", e.g. `info_slides` vs. `slides` for Vignettes. However, inside these folders, we follow the same structure, i.e. subfolders for controller actions.
- May contain one of the following special subfolders:
  - `shared`: for shared partials, components etc. used in multiple actions.
  - `form`: for form-related partials, components etc. used in multiple actions, e.g. see `vignettes/slides/form/_form.html.erb` and the related `_form.js`.
  - `mails`: for email views, e.g. see `feedbacks/mails`.
- May contain a root-level `.js` and `.scss` file with the same name as the topic folder (e.g. `lectures.js` and `lectures.scss`) for code that is used across multiple actions. If some parts of code inside these files are only used in a specific action, move them to the corresponding folder. Only code that is relaly *needed* (not just only imported) from multiple other files should live in these root-level files. A `.scss` is more common to find here than a `.js` file since CSS-rultes usually apply to multiple actions.
- These rules may be bent in some very specific cases (with strong reasons), but should serve as a guideline for most scenarios. But always critically question the structure.


Further rules:

- JS Stimulus Controllers end in `.controller.js`.
- Historically, we have many `.coffee` files. New code should avoid CoffeeScript. Use JavaScript instead. See #698 for more details.
- Historically, we have many `.js.erb` files. New code should avoid `.js.erb` files (see also [this disclaimer](https://github.com/ElMassimo/vite-plugin-erb?tab=readme-ov-file#disclaimer-%EF%B8%8F)). Use `.js` files instead. Favor sending HTML responses from the backend instead of JS or CoffeScript responses.
- Use `.scss` files for stylesheets. Avoid `.css` files. [Might rethink this as nowadays pure CSS has gotten quite powerful.]
