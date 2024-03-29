<p align="center">
  <img src="https://user-images.githubusercontent.com/37160523/228801673-236a081f-40e9-47ca-add6-da1b2d6de3fa.png" width="200px" />

  <h3 align="center">MaMpf</h3>
  <p align="center">Mathematische Medienplattform</p>
</p>

## 💡 About

**MaMpf (*Mathematische Medienplattform*)** is an innovative open source E-Learning platform for the mathematical sciences.
Central point is the interconnection between different content in the sense
of a hypermedia system.

MaMpf uses the contextual classification of a course as visual leitmotiv,
instead of organizational aspects.

![mampf-gui](public/mampf-gui-transparent.png)

MaMpf comes with its own hypermedia player and editor THymE
(*The hypermedia Experience*). ThymeE uses the internal structure of
mathematical content (consisting of theorems, remarks, definitions etc.) and allows
exact navigation between content that is related, but temporally apart.
References can be created not only to content within the same video, but within
the whole MaMpf database.

![thyme](public/thyme.png)

ThymE is lean and makes use of WebVTT and HTML5 video capabilites
of modern browsers. A sample hypervideo can be found
[here](https://mampf.mathi.uni-heidelberg.de/media/384/play).

MaMpf is equipped with a tagging system and rich visualisations for content relations,
making use of [cytoscape.js](http://js.cytoscape.org/).

![tags](public/tag_visualisation.png)

MaMpf has a quiz system that allows you to create complex quizzes quite easily.

![quizzes](public/quizzes.png)

MaMpf makes use of the JS based symbolic math expression evaluator
[nerdamer](https://github.com/jiggzson/nerdamer) to parse student's input in quizzes.


For more information see this [blog](https://mampfdev.wordpress.com).
There you can also find a [screenshot gallery](https://mampfdev.wordpress.com/gallery/).
## System background

[![MaMpf](https://img.shields.io/endpoint?url=https://dashboard.cypress.io/badge/simple/v45wg9/main&style=flat&logo=cypress)](https://dashboard.cypress.io/projects/v45wg9/runs)
[![codecov](https://codecov.io/gh/MaMpf-HD/mampf/branch/main/graph/badge.svg?token=x7Zq3m5lVH)](https://codecov.io/gh/MaMpf-HD/mampf)

MaMpf is implemented in Ruby on Rails.

* Ruby version: 3.1.4
* Rails Version: 7.0.4.3
* Test suite: rspec, cypress
* support for I18n

## 💻 Installation (with docker compose)

To easily try out MaMpf you can use `docker compose`. Clone the MaMpf repository and run `docker compose`:

```
git clone -b main --recursive https://github.com/MaMpf-HD/mampf.git
cd mampf/docker/development/
docker compose up
```

See the full installation guide [here](./INSTALL.md).
