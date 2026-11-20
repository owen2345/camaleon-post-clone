# Change Log

## Unreleased

### Tooling: CI runs the suite against Camaleon master

An advisory check runs the suite against the `master` branch of camaleon_cms, on each pull request and each push to `master`. The RSpec check of CI shows the camaleon_cms version that it tests. Development tooling only. [#5](https://github.com/owen2345/camaleon-post-clone/pull/5).

### Fix: cloning keeps the title translations, and the custom fields option works

A translated post cloned with the plugin got each title translation replaced by the slug translation plus " (clone)"; the title translation now gets the suffix. With "Clone custom fields" enabled, cloning raised because the plugin named `field_values`, an association camaleon_cms 2.8.0 renamed to `custom_field_values`; the custom field values are copied again. [#2](https://github.com/owen2345/camaleon-post-clone/pull/2).

### Tooling: test suite, linting, CI, releases and core cross-testing

Modernizes the gemspec and toolchain (Ruby 3.4.10, a committed `Gemfile.lock` on Rails 8.1 and `camaleon_cms >= 2.9.4`), adds a camaleon_cms-backed RSpec suite, RuboCop with the camaleon_cms plugin set, a CI workflow, the manually dispatched Release workflow shared with the other Camaleon plugins, and a callable **Core compatibility** workflow that camaleon_cms runs against its own commits (`CAMALEON_CMS_PATH` sources the core from a local checkout). Development tooling only; the packaged gem's behavior is unchanged. [#1](https://github.com/owen2345/camaleon-post-clone/pull/1).

### Fix: plugin config parses under json 3

`config/camaleon_plugin.json` carried a `//` comment, which the json gem no longer accepts by default as of 3.0, so a host app resolving json 3.x raised `JSON::ParserError` at boot. The file is now plain JSON. [#1](https://github.com/owen2345/camaleon-post-clone/pull/1).
