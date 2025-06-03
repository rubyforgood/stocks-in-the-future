const shadcnConfig = require('./config/shadcn.tailwind.js');

module.exports = {
  ...shadcnConfig,
  theme: {
    ...shadcnConfig.theme,
    extend: {
      ...shadcnConfig.theme.extend,
      colors: {
        ...shadcnConfig.theme.extend.colors,
        'primary-color': {
          DEFAULT: '#00698C',
        },
      },
    },
  },
};
