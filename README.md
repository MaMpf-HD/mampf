<div align="center">
  <a href="https://mampf.mathi.uni-heidelberg.de/">
    <img src="https://github.com/user-attachments/assets/85ef92e1-f37d-4a67-b721-f103abb7c7c6"
      width="130px" alt="MaMpf Logo"/>
  </a>

  <div align="center">
    <h3 align="center">MaMpf</h3>
    <p>
      <strong>Mathematical Media Platform for universities</strong>
    </p>
  </div>
  <div align="center">
    <a href="https://mampf.mathi.uni-heidelberg.de">Website (🇩🇪/🇺🇸)</a>
    | <a href="https://mampf.blog/">Blog (🇩🇪)</a>
    | <a href="https://mampf-hd.github.io/mampf/">User docs (🇩🇪)</a>
    | <a href="https://github.com/MaMpf-HD/mampf/wiki">Dev wiki (🇺🇸)</a>
    <br><sub>Create your own free account <a href="https://mampf.mathi.uni-heidelberg.de">here</a>.
    Note the <a href="https://mampf-hd.github.io/mampf/">user docs</a> are outdated with respect to the screenshots showcased over there.</sub>
  </div>
</div>


## 💡 About / Motivation

MaMpf is an innovative open source e-learning platform for the mathematical sciences developed at the [Institute for Mathematics at Heidelberg University](https://www.math.uni-heidelberg.de/en). It's actively used in teaching and learning; you can [register for free here](https://mampf.mathi.uni-heidelberg.de/) (no student email required). Our platform is fully available in English & German.

<a href="https://mampf.mathi.uni-heidelberg.de/">
    <img alt="MaMpf landing page used to log in" src="https://github.com/user-attachments/assets/1787ba6a-6807-4cd2-ac26-37cbf5267348">
</a>

MaMpf aims to be a hypermedia system for mathematical content. Like _moodle_, it provides a platform for lecturers to upload & organize their teaching material including videos and scripts. But MaMpf goes beyond that and eases learning through interconnected contents:
- 🎞 **Lecture videos** can be enriched with a navigation that allows students to jump to specific parts of the video, e.g. mathematical definitions, theorems, examples etc. References to other media are also possible, e.g. to different lecture videos / quizzes / worked examples etc.
- 🏷 Any media can be **tagged** with keywords. This allows students to easily find content related to a specific topic and discover how items are connected in a **graph view**.
- 🕹 Interactive **quizzes** allow students to test their understanding of the material. The system can automatically evaluate the answers and provide direct feedback, e.g. explain why an answer is wrong or provide a link to the relevant part of the video or an additional "worked example" video.
- 👩‍🏫 Students can sign up for tutorials and form teams themselves. Tutors are then able to manage the groups and upload corrected homework assignments for their students.
- 🗨 A **comment system** allows students to ask questions about the material in the context of the specific video/script or in a general forum. Lecturers will get a notification when a new comment is posted (of course adjustable). Students may choose their own alias name when posting comments in order to stay anonymous.

This is just a brief overview of the feature set. You may think of MaMpf as a mix of _Moodle_, _Khan Academy_ and _YouTube_. But it's more than that as features are tailored to the needs of the mathematical sciences and a university context. Start exploring MaMpf [here](https://mampf.mathi.uni-heidelberg.de/).


## 📷 Screenshots

To give you a closer look, here are some **screenshots** taken from our live system (those screenshots typically get outdated quickly as MaMpf is actively developed):

<details>
  <summary>Video player</summary>
  
  Try out the video player [here](https://mampf.mathi.uni-heidelberg.de/media/384/play) (even without any account). Press `i` to open the outline on the right. It can hold references to other parts of the video or other items in the whole MaMpf database. The player makes use of WebVTT and HTML5 video capabilities of modern browsers.

  <a href="https://mampf.mathi.uni-heidelberg.de/media/384/play">
    <img src="https://github.com/MaMpf-HD/mampf/assets/37160523/ff049eeb-3c25-4db0-a21e-efd51e566256" alt="MaMpf video player"/>
  </a>
</details>

<details>
  <summary>Courses overview</summary>
  
  Here, users can select courses from the current semester or from previous ones.

  ![User courses view](https://github.com/MaMpf-HD/mampf/assets/37160523/a1e386ad-7642-49f2-aecf-f2f0722cc3c1)
</details>

<details>
  <summary>Lectures overview</summary>
  
  In the lectures view, users can click on a lecture to see the video.

  ![User lectures view](https://github.com/MaMpf-HD/mampf/assets/37160523/a3936d73-dc45-489d-85f8-68326f61654a)
</details>

<details>
  <summary>Graph tag search</summary>
  
  MaMpf is equipped with a tagging system and rich visualizations for content relations, making use of [cytoscape.js](http://js.cytoscape.org/).

  ![Search graph](https://github.com/MaMpf-HD/mampf/assets/37160523/cd54b651-70c0-439d-a8dd-01de95995cb5)
</details>

<details>
  <summary>Quizzes</summary>

  Users can play quizzes in MaMpf and get immediate feedback. In order to parse student's input in quizzes (e.g. when they enter a symbolic expression), MaMpf makes use of the JS based symbolic math expression evaluator [nerdamer](https://github.com/jiggzson/nerdamer).

  ![playing a quiz](https://github.com/MaMpf-HD/mampf/assets/37160523/baa3ae6d-e7bf-4ecc-9db0-22cab367d4ee)

  Lecturers can create quizzes and edit them in a graph:

  ![admin view for a quiz](https://github.com/MaMpf-HD/mampf/assets/37160523/855089b4-9358-4ff5-a9b0-d1aa89962c20)
</details>

<details>
  <summary>Comments</summary>

  Users can post comments directly on videos. LaTeX is supported and rendered via [KaTeX](https://katex.org/).

  ![posting a comment](https://github.com/MaMpf-HD/mampf/assets/37160523/5ee4b51c-5ea5-4cf5-bf25-a0048434cb1f)
</details>


## 💻 Development

MaMpf is a **Ruby on Rails** application with a **PostgreSQL** database. For our frontend styling, we rely on **Bootstrap**. Our [website](https://mampf.mathi.uni-heidelberg.de/) is hosted on a server at Heidelberg University. We use docker (compose) for development and deployment.

MaMpf is actively developed & maintained. If you are interested in using MaMpf at your university, get [in touch](mailto:mampf@mathi.uni-heidelberg.de). But please note that we're a very small team and can't provide support for setting up your own instance of MaMpf at the moment.

If you want to develop MaMpf, check out our [Contribution guide](./CONTRIBUTING.md) (for external users that are not employed through the MaMpf team) and the [Setup Wiki](https://github.com/MaMpf-HD/mampf/wiki/Setup) (we make use of Dev Containers).

<a href="https://mampf.mathi.uni-heidelberg.de/">
  <img src="https://github.com/user-attachments/assets/35268bae-a7d4-4a7b-b81a-3fd5aed5fe71"
    alt="MaMpf footer"/>
</a>
