// eslint.config.js
module.exports = {
    languageOptions: {
      globals: {
        browser: true,
        node: true,
      },
      parserOptions: {
        ecmaVersion: 2021,
        sourceType: 'module',
      },
    },
    rules: {
      'max-len': ['error', { code: 80 }],
      'indent': ['error', 2],
      'object-curly-spacing': ['error', 'never'],
    },
  };
  