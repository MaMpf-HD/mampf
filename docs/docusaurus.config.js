/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: 'MaMpf',
  tagline: 'Mathematische Medienplattform',
  url: 'https://mampf-hd.github.io/mampf',
  baseUrl: '/mampf/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'MaMpf-HD', // Usually your GitHub org/user name.
  projectName: 'mampf', // Usually your repo name.
  themeConfig: {
    navbar: {
      title: 'MaMpf',
      logo: {
        alt: 'MaMpf-Logo',
        src: 'img/logo.svg',
      },
      items: [{
        to: 'mampf-pages/',
        activeBasePath: 'mampf-pages',
        label: 'Pages',
        position: 'left',
       },
       {
         to: 'tutorials/',
         activeBasePath: 'tutorials',
         label: 'Tutorials',
         position: 'left',
        },
        {
          to: 'mampf-pages/terminology',
          label: 'Terminology',
          position: 'left',
         },
         {
           to: 'conception/',
           activeBasePath: 'conception',
           label: 'Conception',
           position: 'left',
          },
        {
          href: 'https://mampf.blog',
          label: 'Blog',
          position: 'left'
        },
        {
          type: 'localeDropdown',
          position: 'right',
        },
        {
          href: 'https://github.com/mampf-hd/mampf',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [{
          title: 'Docs',
          items: [{
            label: 'Getting Started',
            to: 'docs/',
          }, ],
        },

        {
          title: 'More',
          items: [{
              label: 'Blog',
              href:"https://mampf.blog",
            },
            {
              label: 'GitHub',
              href: 'https://github.com/mampf-hd/mampf',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} MaMpf Developers and Contributors. Built with Docusaurus.`,
    },
  },
  presets: [
    [
      '@docusaurus/preset-classic',
      {
        docs: {
          sidebarPath: require.resolve('./sidebars.js'),
          // Please change this to your repo.
          editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        },
        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      },
    ],
  ],
  i18n: {
    defaultLocale: 'en',
    locales: ['en', 'de'],
    localeConfigs: {
      en: {
        label: 'English',
      },
      de: {
        label: 'Deutsch',
      },
    },
  },
  plugins: [
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'mampf-pages',
        path: 'mampf-pages',
        routeBasePath: 'mampf-pages',
        sidebarPath: require.resolve('./sidebarsPages.js'),
        editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        // ... other options
      },
    ],
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'tutorials',
        path: 'tutorials',
        routeBasePath: 'tutorials',
        sidebarPath: require.resolve('./sidebarsTutorials.js'),
        editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        // ... other options
      },
    ],
    [ '@docusaurus/plugin-content-docs',
      {
        id: 'lecturers',
        path: 'lecturers',
        routeBasePath: 'lecturers',
        sidebarPath: require.resolve('./sidebarsLecturers.js'),
        editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        // ... other options
      },
    ],
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'devel',
        path: 'devel',
        routeBasePath: 'devel',
        sidebarPath: require.resolve('./sidebarsDevel.js'),
        editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        // ... other options
      },
    ]
  ]
};
