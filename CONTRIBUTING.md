# Contributing
The following highlight some guidelines for contributing to Crichton and submitting pull requests.

## Background
At the heart of Crichton is the [ALPS specification](http://alps.io/spec/index.html). It is important that 
functionality that impacts Crichton's resource descriptors conforms to and preserves the existing ALPS-related
implementations so that profiles can be properly generated and referenced.

## Guidelines
Crichton aspires follow ideas set out by Bob Martin in [Clean Code](http://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882). 
As such, the following are some guidelines to think about as you code:

### Every file should be easy to read.
* Use pronouncable, meaningful names that reveal intentions.
* Code should read like a top-down narrative starting with required modules to make things easy to find.
* Use three or less method arguments.
* Stay DRY and keep methods, classes and modules sizes small.

### Only add comments that actually add clarification.
* If you are explaining bad code, fix the code.
* Aspire to self-documenting variable and method names.

### Only do one thing.
* Methods should call other methods vs. writing larger methods that violate SRP.
* Every method should be followed by any methods it calls (as the next level of abstraction).

### Specs should be F.I.R.S.T.
* Fast - run quickly.
* Independent - not rely on previous tests.
* Repeatable - work in any environment.
* Self-validating - examples are written to document what passes.
* Timely - Follow TDD/BDD principles.

## Pull Requests
* Make your feature addition or bug fix that conforms to the [style guide](https://github.com/mdsol/ruby-style-guide).
* Add pertinent [YARD](http://yardoc.org/guides/index.html) documentation and check that it is correctly formatted by 
running `$ rake doc:yard` locally.
* Add specs for it. This is important so future versions don't break it unintentionally.
* Send a pull request.
* For a proposed version bump, update the CHANGELOG.
* Run specs and confirm coverage for your code additions:

    ```
    $ bundle exec appraisal install
    $ bundle exec appraisal rspec
    ```
