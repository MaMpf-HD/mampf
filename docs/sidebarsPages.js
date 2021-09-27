module.exports = {
  docs: [
    "mampf",
    "structure",
    {
      type: 'category',
      label: 'Pages for Every User',
      items: [
        'all-pages',
        {
          type: 'category',
          label: 'By Function',
          items: ['administrative', 'active', 'informative', 'communicative',],
        },
        {
          type: 'category',
          label: 'By Manner of Access',
          items: ['nav-bar-pages', 'sidebar-pages',],
        },
      ],
    },
    'all-pages-ed',
    'all-pages-ad',
  ],
};
