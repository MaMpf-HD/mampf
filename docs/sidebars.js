module.exports = {
  docs: [
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
          items: ['nav-bar', 'sidebar', 'event-series-list',],
        },
        'all-pages',
        'getting-started'
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
