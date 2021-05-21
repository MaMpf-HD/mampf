module.exports = {
  docs: [
    {
      type: 'category',
      label: 'Seiten',
      items: [
        'structure',
        {
          type: 'category',
          label: 'Nach Funktion',
          items: ['administrative', 'active', 'informative', 'communicative',],
        },
        {
          type: 'category',
          label: 'Nach Erreichbarkeit',
          items: ['nav-bar', 'sidebar', 'event-series-list',],
        },
        'all-pages',
        'getting-started'
      ],
    },
    'tutorials',
    {
      type: 'category',
      label: 'Konzeption',
      items: [
        'navigation', 'design-and-structure', 'connecting-concepts',
      ],
    },
    'terminology',
  ],
};
