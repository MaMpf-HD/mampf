module.exports = {
  docs: [
    "mampf",
    {
      type: 'category',
      label: 'Pages',
      items: [
        'structure',
        {
          type: 'category',
          label: 'By Function',
          items: ['administrative', 'active', 'informative', 'communicative',],
        },
        {
          type: 'category',
          label: 'By Access',
          items: ['nav-bar-pages', 'sidebar-pages',],
        },
        'all-pages',
      ],
    },
    'tutorials',
    {
      type: 'category',
      label: 'Conception',
      items: [
        'navigation', 'design-and-structure', 'connecting-concepts',
      ],
    },
    'terminology',
  ],
};
