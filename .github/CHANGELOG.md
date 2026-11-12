# Changelog

## [0.2.0](https://github.com/cycneuramus/nimpsort/compare/v0.1.1...v0.2.0) (2026-11-12)


### Features

* Sort in place and preserve each import item's whitespace ([fc5f821](https://github.com/cycneuramus/nimpsort/commit/fc5f8212308d7db2389546b05810996dbc63045d))
* Sort indented imports ([0068d81](https://github.com/cycneuramus/nimpsort/commit/0068d81230353e91b8d0887efed8e5385a74f8fd))
* Support multiple input files ([0c73073](https://github.com/cycneuramus/nimpsort/commit/0c730733978bbf54a396b632e0c06e2cc5921dbd))


### Bug Fixes

* Don't let 'not-safe-to-sort' keywords in comments prevent sorting ([05d59dd](https://github.com/cycneuramus/nimpsort/commit/05d59ddc5547cd1ad949524fa7002aca620ca686))
* Don't quit on file not found (there may be more files to process) ([f036e67](https://github.com/cycneuramus/nimpsort/commit/f036e67e090275108365f3f84658c21495251c13))
* Don't treat identifiers starting with 'import' as imports ([3f2c191](https://github.com/cycneuramus/nimpsort/commit/3f2c1912af8fb6f5b6ee9bccdc08197e999084f1))
* Don't write file if no change is needed ([4b95897](https://github.com/cycneuramus/nimpsort/commit/4b95897e1babb9ad7e2155ac3fbf08fb41861d1f))
* Exclude path from program name ([1fa45ae](https://github.com/cycneuramus/nimpsort/commit/1fa45ae27bdf40c1ee1fa1e29c5f0aade0e4725c))
* Handle multi-line import statements ([31093e8](https://github.com/cycneuramus/nimpsort/commit/31093e8e467d628188312fab353126b05e0daaa6))
* Handle multiple and nested bracket groups ([784e69f](https://github.com/cycneuramus/nimpsort/commit/784e69f93040eb717433576339bc42c1a8d4d588))
* Ignore triple-quoted strings ([bbea0f3](https://github.com/cycneuramus/nimpsort/commit/bbea0f3e8a995f0af260f76350897fd9d252a9f8))

## [0.1.1](https://github.com/cycneuramus/nimpsort/compare/v0.1.0...v0.1.1) (2025-03-24)


### Bug Fixes

* Index out of range on missing closing bracket ([7b4c20b](https://github.com/cycneuramus/nimpsort/commit/7b4c20b66b4bd384a118656c96781df87ed0c3a5))
