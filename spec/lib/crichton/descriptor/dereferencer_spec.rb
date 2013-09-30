require 'spec_helper'
require 'crichton/descriptor/dereferencer'

module Crichton
  module Descriptor
    describe Dereferencer do

      context 'build_dereferenced_hash_descriptor' do

        it 'dereferences a local reference' do
          @ids_registry = {
            'example#other_name' =>
              {
                'value2' => 'something else'
              }}
          descriptor_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'href' => 'other_name',
                          'value' => 'something'
                      },
                      'other_name' => {
                          'value2' => 'something else'
                      }

                  }
              }
            }
          }
          reference_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'dhref' => 'other_name',
                          'value2' => 'something else',
                          'value' => 'something'
                      },
                      'other_name' => {
                          'value2' => 'something else'
                      }
                  }
              }
            }
          }
          dereferencer = Dereferencer.new(@ids_registry) {}
          deref_hash = dereferencer.build_dereferenced_hash_descriptor('example', descriptor_hash)
          deref_hash.should == reference_hash
        end

        it 'gives a local value priority over a remote value is the local value is after the href' do
          @ids_registry = {
            'example#other_name' =>
              {
                'value' => 'something else'
              }}
          descriptor_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'href' => 'other_name',
                          'value' => 'something'
                      },
                      'other_name' => {
                          'value' => 'something else'
                      }
                  }
              }
            }
          }
          reference_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'dhref' => 'other_name',
                          'value' => 'something'
                      },
                      'other_name' => {
                          'value' => 'something else'
                      }
                  }
              }
            }
          }
          dereferencer = Dereferencer.new(@ids_registry) {}
          deref_hash = dereferencer.build_dereferenced_hash_descriptor('example', descriptor_hash)
          deref_hash.should == reference_hash
        end

        it 'gives a remote value priority over a local value if the remote value is after the href' do
          @ids_registry = {
            'example#other_name' =>
              {
                'value' => 'something else'
              }
            }
          descriptor_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'value' => 'something',
                          'href' => 'other_name'
                      },
                      'other_name' => {
                          'value' => 'something else'
                      }
                  }
              }
            }
          }
          reference_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'value' => 'something else',
                          'dhref' => 'other_name'
                      },
                      'other_name' => {
                          'value' => 'something else'
                      }
                  }
              }
            }
          }
          dereferencer = Dereferencer.new(@ids_registry) {}
          deref_hash = dereferencer.build_dereferenced_hash_descriptor('example', descriptor_hash)
          deref_hash.should == reference_hash
        end

        it 'deep-merges the remote value' do
          @ids_registry = {
            'example#other_name' =>
                {
                    'value' => 'something else',
                    'hierarchy' => {'k' => 'v'}
                }
            }
          descriptor_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'value' => 'something',
                          'hierarchy' => {'l' => 'm'},
                          'href' => 'other_name'
                      },
                      'other_name' => {
                          'value' => 'something else',
                          'hierarchy' => {'k' => 'v'}
                      }
                  }
              }
            }
          }
          reference_hash = {
              'id' => "example",
              'descriptors' => {
              'example' => {
                  'descriptors' => {
                      'some_name' => {
                          'value' => 'something else',
                          'hierarchy' => {'k' => 'v', 'l' => 'm'},
                          'dhref' => 'other_name'
                      },
                      'other_name' => {
                          'value' => 'something else',
                          'hierarchy' => {'k' => 'v'}
                      }
                  }
              }
            }
          }
          dereferencer = Dereferencer.new(@ids_registry) {}
          deref_hash = dereferencer.build_dereferenced_hash_descriptor('example', descriptor_hash)
          deref_hash.should == reference_hash
        end

      end
    end
  end
end
