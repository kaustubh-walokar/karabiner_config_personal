const { table } = require('console')
const prettier = require('prettier')

/** @type {import('prettier').Options} */
module.exports = {
  tabWidth: 2,
  useTabs: false,
  singleQuote: true,
  semi: false,
  trailingComma: 'all',
  bracketSameLine: true,
  files: '**/*.ts',
}
