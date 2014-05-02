require 'spec_helper'
require 'crichton/descriptor/dereferencer'

module Crichton
  module Descriptor
    describe Dereferencer do

      context 'build_dereferenced_hash_descriptor' do
        let(:build_options_registry) do
          ->(name,hash){ [name, hash] }
        end

        it 'dereferences a local reference' do
          @ids_registry = {
            'example#other_name' =>
              {
                'value2' => 'something else'
              }}
          descriptor_hash = {
              'id' => "example",
              'links' => {
                'self' => 'example'
              },
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
              'links' => {
                  'self' => 'example'
              },
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

          dereferencer = Dereferencer.new(descriptor_hash, &build_options_registry)
          deref_hash = dereferencer.dereference_hash_descriptor(@ids_registry, {})
          deref_hash.should == reference_hash
        end

        context 'href is url fragment' do
          it 'dereferences a local reference' do
            @ids_registry = {
                'example#other_name' =>
                    {
                        'value2' => 'something else'
                    }}
            descriptor_hash = {
                'id' => "example",
                'links' => {
                    'self' => 'example'
                },
                'descriptors' => {
                    'example' => {
                        'descriptors' => {
                            'some_name' => {
                                'href' => 'example#other_name',
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
                'links' => {
                    'self' => 'example'
                },
                'descriptors' => {
                    'example' => {
                        'descriptors' => {
                            'some_name' => {
                                'dhref' => 'example#other_name',
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

            dereferencer = Dereferencer.new(descriptor_hash, &build_options_registry)
            deref_hash = dereferencer.dereference_hash_descriptor(@ids_registry, {})
            deref_hash.should == reference_hash
          end

          context 'case different local reference' do
            it 'doesnt dereference a local reference with case different document id' do
              @ids_registry = {
                  'example#other_name' =>
                      {
                          'value2' => 'something else'
                      }}
              descriptor_hash = {
                  'id' => "example",
                  'links' => {
                      'self' => 'example'
                  },
                  'descriptors' => {
                      'example' => {
                          'descriptors' => {
                              'some_name' => {
                                  'href' => 'example#Other_name',
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
                  'links' => {
                      'self' => 'example'
                  },
                  'descriptors' => {
                      'example' => {
                          'descriptors' => {
                              'some_name' => {
                                  'dhref' => 'example#Other_name',
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

              dereferencer = Dereferencer.new(descriptor_hash, &build_options_registry)
              deref_hash = dereferencer.dereference_hash_descriptor(@ids_registry, {})
              deref_hash.should_not == reference_hash
            end

            it 'doesnt dereference a local reference with case different descriptor id' do
              @ids_registry = {
                  'example#other_name' =>
                      {
                          'value2' => 'something else'
                      }}
              descriptor_hash = {
                  'id' => "example",
                  'links' => {
                      'self' => 'example'
                  },
                  'descriptors' => {
                      'example' => {
                          'descriptors' => {
                              'some_name' => {
                                  'href' => 'Example#other_name',
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
                  'links' => {
                      'self' => 'example'
                  },
                  'descriptors' => {
                      'example' => {
                          'descriptors' => {
                              'some_name' => {
                                  'dhref' => 'Example#other_name',
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

              dereferencer = Dereferencer.new(descriptor_hash, &build_options_registry)
              deref_hash = dereferencer.dereference_hash_descriptor(@ids_registry, {})
              deref_hash.should_not == reference_hash
            end
          end
        end

        it 'gives a local value priority over a remote value is the local value is after the href' do
          @ids_registry = {
            'example#other_name' =>
              {
                'value' => 'something else'
              }}
          descriptor_hash = {
              'id' => "example",
              'links' => {
                  'self' => 'example'
              },
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
              'links' => {
                  'self' => 'example'
              },
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

          dereferencer = Dereferencer.new(descriptor_hash, &build_options_registry)
          deref_hash = dereferencer.dereference_hash_descriptor(@ids_registry, {})
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
              'links' => {
                  'self' => 'example'
              },
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
              'links' => {
                  'self' => 'example'
              },
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

          dereferencer = Dereferencer.new(descriptor_hash, &build_options_registry)
          deref_hash = dereferencer.dereference_hash_descriptor(@ids_registry, {})
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
              'links' => {
                  'self' => 'example'
              },
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
              'links' => {
                  'self' => 'example'
              },
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

          dereferencer = Dereferencer.new(descriptor_hash, &build_options_registry)
          deref_hash = dereferencer.dereference_hash_descriptor(@ids_registry, {})
          deref_hash.should == reference_hash
        end

      end
    end
  end
end
