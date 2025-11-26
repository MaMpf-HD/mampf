*To be considered alongside the [MaMpf Wiki](https://github.com/MaMpf-HD/mampf/wiki).*

# Frontend folder structure

Each controller has a corresponding "topic folder" with all related frontend inside, e.g. we have a `app/controllers/lectures_controller.rb`, therefore we also have an `app/frontend/lectures/` folder.

## Topic folders

A topic folder (e.g. `lectures`)

- Contains all frontend-related code for a specific controller (e.g. `lectures_controller.rb`). This includes views, partials, JavaScript, Stylesheets, ViewComponents etc.
- **Has subfolders corresponding to controller actions** (e.g. `edit`, `show`, `index`, `search` etc.). Shorter names may be used for folder names, e.g. `announcements` instead of `show_announcements` or `subscribe` instead of `subscribe_page`.
  - Inside these subfolders, the trinity of html, css and js should be placed together by naming convention, e.g. `index.html.erb`, `index.js`, `index.scss` for the `index` action. For partials, it can be beneficial to also include a `_` as prefix for JS/CSS files in order to have related files displayed right next to each other in the file tree.<br>
  [Additional files can be added as needed, e.g. `do_something_specific.js`. However, if the folder is getting too big and too messy, consider splitting it up into more folders.]
  - May contain further subfolders, consider for example `vignettes/slides/form/answer_types/`. However, deeply nesting should be avoided.
  - [for very big topics] These subfolders can also refer to semantic boundaries, e.g. `info_slides` vs. `slides` for Vignettes. However, inside these folders, we follow the same structure, i.e. subfolders for controller actions.
- May contain one of the following special subfolders:
  - `shared`: for shared partials, components etc. used in multiple actions.
  - `form`: for form-related partials, components etc. used in multiple actions, e.g. see `vignettes/slides/form/_form.html.erb` and the related `_form.js`.
  - `mails`: for email views, e.g. see `feedbacks/mails`.
- May contain a root-level `.js` and `.scss` file with the same name as the topic folder (e.g. `lectures.js` and `lectures.scss`) for code that is used across multiple actions. If parts of the code inside these files are only used in a specific action, move these parts to the corresponding folder. Only code that is really *needed* (not just only imported) from multiple other files should live in these root-level files. A `.scss` is more common to find here than a `.js` file since CSS-rultes usually apply to multiple actions.
- These rules may be bent in some very specific cases, but should serve as a guideline for most scenarios. Always critically question the structure.

Further rules:

- JS Stimulus Controllers end in `.controller.js`.
- Historically, we have many `.coffee` files. New code must not use CoffeeScript anymore. Use JavaScript instead. See #698 for more details.

---

> Why don't we use a folder structure based on file extensions as is usual in Rails apps?

In the official Rails asset pipeline (even with Propshaft), the folder structure is based on file extensions, e.g. `app/assets/javascripts`, `app/assets/stylesheets`, `app/views` etc. However, we oftentimes find ourselves in the situation of needing to create or modify an existing *feature*.<br>Instead of recreating our entire feature hierarchy in three different folders, we acknowledge that frontend development is more often than not about the trinity of JS/CSS/HTML files. Therefore, it makes sense — at least for us — to place them together and group files *per user view* (which usually corresponds to a controller action).

In the proposed structure, a subfolder corresponds to a controller action. This drastically limits the scope such that you will usually find only a handful of files per folder. This makes it easy to discover related files, e.g. `index.html.erb`, `index.js` and `index.scss` for the `vignettes/questionnaires/index` action.

That being said, in your favorite IDE, every file is actually only one search away. However, for this, you oftentimes need to know how files are named. Having related files close to together eases this discovery process and working on actual _features_.
