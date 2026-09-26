const test = require('node:test')
const { execFileSync } = require('node:child_process')
const path = require('node:path')
test('mediation discovery and Gradle dependency behavior', () => {
  execFileSync('python3', [path.join(__dirname, 'mediation_tools.py')], { stdio: 'pipe' })
})
