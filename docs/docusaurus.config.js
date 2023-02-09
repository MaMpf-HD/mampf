/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: 'MaMpf',
  tagline: 'Mathematische Medienplattform',
  url: 'https://mampf-hd.github.io/',
  baseUrl: '/mampf/',
  onBrokenLinks: 'warn',
  onBrokenMarkdownLinks: 'warn',
  favicon: 'img/favicon.ico',
  organizationName: 'MaMpf-HD', // Usually your GitHub org/user name.
  projectName: 'mampf', // Usually your repo name.
  themeConfig: {
    tableOfContents: {
      minHeadingLevel: 2,
      maxHeadingLevel: 4,
    },
    colorMode: {
      defaultMode: 'light',
      disableSwitch: true,
    },
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
          to: 'terminology/',
          label: 'Terminology',
          position: 'left',
         },
         {
           to: 'concept/',
           activeBasePath: 'concept',
           label: 'Concept',
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
        {
          href: 'https://mampf.mathi.uni-heidelberg.de/',
          label: 'MaMpf',
          position: 'right'
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [{
          title: 'Docs',
          items: [{
            label: 'Getting Started',
            to: 'mampf-pages',
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
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'terminology',
        path: 'terminology',
        routeBasePath: 'terminology',
        editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        // ... other options
      },
    ],
    [
      '@docusaurus/plugin-content-docs',
      {
        id: 'concept',
        path: 'concept',
        routeBasePath: 'concept',
        editUrl: 'https://github.com/mampf-hd/mampf/edit/main/docs/',
        // ... other options
      },
    ],
  ]
};
