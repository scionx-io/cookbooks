# Changelog

## [1.1.0](https://github.com/scionx-io/cookbooks/compare/tron.rb-v1.0.0...tron.rb/v1.1.0) (2025-10-17)


### Features

* add automated release workflows with GitHub Actions ([a236d51](https://github.com/scionx-io/cookbooks/commit/a236d51fd0de52faa45f494012567c6ab4ad41b9))
* complete modular gem refactoring with Rails integration support ([78eb09e](https://github.com/scionx-io/cookbooks/commit/78eb09e278e42f06e2123ab77f85ca71f619d0d6))
* complete Ruby implementation with working account resources API ([b80ea4b](https://github.com/scionx-io/cookbooks/commit/b80ea4be27d819e2ee9200fc0f26576ac079984d))


### Bug Fixes

* update Bundler version compatibility for Ruby 2.7 ([1c15ed8](https://github.com/scionx-io/cookbooks/commit/1c15ed881b34c86febf74bcf75bfbd0ec3aa5a56))
* update RubyGems release workflow with correct Ruby version and branch name\n\n- Add .ruby-version file to specify Ruby version for setup-ruby action\n- Update release workflow to use explicit ruby-version parameter\n- Fix branch reference from 'main' to 'master' in workflows and docs\n- This resolves the GitHub Actions failure due to missing Ruby version ([29657a2](https://github.com/scionx-io/cookbooks/commit/29657a2818407686972b9230629458a4b79fa9e1))
* update workflows for master branch and git config ([ed30429](https://github.com/scionx-io/cookbooks/commit/ed30429eaece2cbcb9b7401ada1caf3eb51d73af))
