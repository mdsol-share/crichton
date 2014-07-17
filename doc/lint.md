# @title Lint Validation Tool

# Overview
Crichton Lint enables you to determine whether a resource descriptor file is well-structured and whether it meets Crichton requirements. Lint validates the logic of a resource descriptor file, and it outputs errors and provides warnings and hints that help you generate an optimal document. 

Since a resource descriptor document is a YAML file, it must first meet the requirements of well-formed YAML. This 
website is one of many to help check to see whether the file is well-formed 
YAML: [YAML parser](http://yaml-online-parser.appspot.com/). 
See the [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml) for more 
information.

Once you have a clean resource descriptor file, invoke Lint using RSpec to make sure that any changes to the file or 
any new requirements to Crichton do not inadvertently produce an error. It is a best practice to generate an RSpec 
file with Crichton Lint for continuous integration purposes.

## Invoking Crichton Lint
You can invoke Lint in two ways. These include using the Lint Ruby gem, rdlint, and running Lint from Rake.

### Using the Crichton Lint Ruby gem executable

Add the Crichton Lint Ruby gem executable, rdlint, to your project:

    bundle exec rdlint <options> <resource descriptor file>

rdlint can validate a descriptor file or, using an `--all` option, can validate all the descriptor files in the current 
project. (The location of descriptor files defaults to an `api_descriptors` directory.)

Options for rdlint include the following:

- `-v` or `--version` - Display the version number of the crichton library.
- `-w` or `--no_warnings` - Suppress all warnings and display errors messages only, if any.
- `-s` or `--strict` - Returns true when all validations pass, false when any descriptor file fails Lint.
- `-a` or `--all` - Validates all `*.yml` and `*.yaml` files found in the resource descriptor directory. Defaults to the 
api_descriptors directory.
- `-h` or `--help` - Displays the standard usage dialog.

Some examples of running rdlint from the root of a project include the following:

- `bundle exec rdlint api_descriptors/file.yml` - Validates a single file.
- `bundle exec rdlint -a (or --all) ` - Validates all files in the resource descriptor directory.
- `bundle exec rdlint -w api_descriptors/file.yml` - Validates a single file and suppresses warning messages.
- `bundle exec rdlint -aw` - Validates all descriptor files and suppresses warning messages.
- `bundle exec rdlint -v api_descriptors/file.yml` - Displays a version message and lint a single file.
- `bundle exec rdlint -s api_descriptors/file.yml` - Validates a single file and outputs "true" or "false" (pass / fail).
- `bundle exec rdlint -as` - Validates all descriptor file and outputs "true" / "false". Returns on the first fail.

There are several mutually exclusive options. These include the following:
- `-s` takes precedence over -w; the warning option is ignored when it is specified together with strict mode (for example, `-sw`).
- `-a` with a specified file name will ignore the file name, the "all" option takes precedence.

### Running Lint from Rake

Projects bundled with the Crichton Lint gem can also use Lint to validate resource descriptor files using Rake. Rake 
accepts up to two parameters with the following invocation possibilities:

- `path_to_filename`
- `all`
- `path_to_filename`, with options `strict`/`no_warnings`/`version`
- `all`, with options `strict`/`no_warnings`/`version`

Examples include:

- `bundle exec rake crichton:lint[<path_to_a_file>]`
- `bundle exec rake crichton:lint[<path_to_a_file>,no_warnings]`
- `bundle exec rake crichton:lint[<path_to_a_file>,strict]`
- `bundle exec rake crichton:lint[<path_to_a_file>,version]`
- `bundle exec rake crichton:lint[all]`
- `bundle exec rake crichton:lint[all,no_warnings]`
- `bundle exec rake crichton:lint[all,no_warnings]`
- `bundle exec rake crichton:lint[all,version]`

For those unfamiliar with Rake, arguments to Rake require brackets. In zsh, you must escape the brackets with `\[...\]`. 
There are no spaces between the two parameters.

## Using Lint with native Ruby
You can use native Ruby to access the Crichton Lint gem.

### Pure Ruby strict mode
For native Ruby access to Lint validation, you can do the following (provided that proper requires have been set up to 
the crichton/lib/lint folder). This will return a pure Ruby true/false return value.

    Lint.validate(<filename>, {strict: true})  # => true or false

### Warning Count and Error Count mode

Available in native Ruby access to lint validation are two addition options: `count: error` and `count: warning`. 
Invoke these as an optional hash, similar to the strict mode above. For example you can invoke the following:

    Lint.validate(<filename>, {count: :error})  # => # of errors found
    Lint.validate(<filename>, {count: :warning})  # => # of warnings found

## Generating RSpec files for Crichton Lint

In the Crichton project, use the file `spec/lib/resource_descriptors/drds_descriptor.rb` as a template to create an 
RSpec test for your project.

The file uses a path to a resource descriptor file that is specific to the Crichton project, but you can update the
following line for your project:

    let(:filename) { File.join(Crichton.descriptor_location, <my descriptor file>) }

The RSpec specification for Crichton employs four simple tests:

- Makes sure that the resource descriptor file specified is correct.
- Tests for an error count.
- Tests for a warning count.
- Does a pass/fail test, returning true or false, with the `--strict` option.

## Related Topics
Click the following links to view documents related to Lint:

* [API Descriptor Documents](api_descriptor_documents.md)
* [Example API Descriptor Document](../spec/fixtures/resource_descriptors/drds_descriptor_v1.yml)
