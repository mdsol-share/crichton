module Support
  module ALPS
    def alps_profile
      {
        'alps' => {
          'doc' => {
            'value' => 'Describes Leviathans.'
          },
          'ext' => [
            {'href' => 'Leviathans#alt', 'value' => 'Alternate.'}
          ],
          'link' => [
            {
              'rel' => 'self', 
              'href' => 'Leviathans'
            }, 
            {
              'rel' => 'help', 
              'href' => 'Things/Leviathans'
            }
          ], 
          'descriptor' => [
            {
              'id' => 'leviathan',
              'doc' => {
                'format' => 'html',
                'value' => '<p>Leviathans are bio-mechanoid ships that move freely among the stars.</p>'
              },
              'ext' => [
                {
                  'href' => 'Leviathans#note',
                  'value' => 'A note.'
                }
              ],
              'type' => 'semantic',
              'descriptor' => [
                {
                  'id' => 'uuid',
                  'doc' => {
                    'value' => 'The UUID of the Leviathan.'
                  },
                  'type' => 'semantic',
                  'href' => 'http://alps.io/schema.org/Text'
                },
                {
                  'id' => 'name',
                  'doc' => {
                    'value' => 'The name of the Leviathan.'
                }, 
                  'type' => 'semantic',
                  'href' => 'http://alps.io/schema.org/Text'
                },
                {
                  'id' => 'create',
                  'doc' => {
                    'value' => 'Creates a Leviathan.'
                  },
                  'type' => 'unsafe',
                  'rt' => 'leviathan',
                  'descriptor' => [
                    {
                      'id' => 'create-leviathan',
                      'link' => [
                        {
                          'rel' => 'self',
                          'href' => 'Leviathans#leviatahn/create/create-leviathan'
                        },
                        {
                          'rel' => 'help',
                          'href' => 'Forms/create-leviathan'
                        }
                      ],
                      'type' => 'semantic',
                      'descriptor' => [
                        {
                          'id' => 'form_name',
                          'doc' => {
                            'value' => 'The name of the Leviathan.'
                          },
                          'name' => 'name',
                          'type' => 'semantic',
                          'href' => 'http://alps.io/schema.org/Text'
                        }
                      ]
                    }
                  ]
                }
              ]
            }                  
          ]
        }
      }
    end

    def alps_profile_with_absolute_links
      {
        'alps' => {
          'doc' => {
            'value' => 'Describes Leviathans.'
          },
          'ext' => [
            {'href' => 'http://alps.io/extensions/serialized_datalist',
             'value' => "{\"size-list\":[\"small\",\"medium\",\"large\"]}"}
          ],
          'link' => [
            {
              'rel' => 'self',
              'href' => 'http://alps.example.com/Leviathans'
            },
            {
              'rel' => 'help',
              'href' => 'http://docs.example.org/Things/Leviathans'
            }
          ],
          'descriptor' => [
            {
              'id' => 'leviathan',
              'doc' => {
                'format' => 'html',
                'value' => '<p>Leviathans are bio-mechanoid ships that move freely among the stars.</p>'
              },
              'ext' => [
                {
                  'href' => 'http://alps.example.com/Leviathans#note',
                  'value' => 'A note.'
                }
              ],
              'type' => 'semantic',
              'descriptor' => [
                {
                  'id' => 'uuid',
                  'doc' => {
                    'value' => 'The UUID of the Leviathan.'
                  },
                  'type' => 'semantic',
                  'href' => 'http://alps.io/schema.org/Text'
                },
                {
                  'id' => 'name',
                  'doc' => {
                    'value' => 'The name of the Leviathan.'
                },
                  'type' => 'semantic',
                  'href' => 'http://alps.io/schema.org/Text'
                },
                {
                  'id' => 'status',
                  'doc' => {
                    'value' => 'How is the Leviathan.'
                  },
                  'type' => 'semantic',
                  'href' => 'http://alps.io/schema.org/Text',
                  'ext' => [
                    {
                      "value" => "{\"id\":\"leviathan_status_options\",\"hash\":{\"new\":\"new\",\"old\":\"old\"}}",
                      'href' => 'http://alps.io/extensions/serialized_options_list'}
                  ],
                },
                {
                 'id' => 'size',
                  'doc' => {
                    'value' => 'How large it is'
                  },
                 'type' => 'semantic',
                 'ext' => [
                   {
                     "value" => "{\"datalist\":\"size-list\"}", 
                     'href' => 'http://alps.io/extensions/serialized_options_list'
                   }
                  ],
                 'href' => 'http://alps.io/schema.org/Text'},
                {
                  'id' => 'create',
                  'doc' => {
                    'value' => 'Creates a Leviathan.'
                  },
                  'type' => 'unsafe',
                  'rt' => 'leviathan',
                  'descriptor' => [
                    {
                      'id' => 'create-leviathan',
                      'link' => [
                        {
                          'rel' => 'self',
                          'href' => 'http://alps.example.com/Leviathans#create-leviathan'
                        },
                        {
                          'rel' => 'help',
                          'href' => 'http://docs.example.org/Forms/create-leviathan'
                        }
                      ],
                      'type' => 'semantic',
                      'descriptor' => [
                        {
                          'id' => 'form_name',
                          'doc' => {
                            'value' => 'The name of the Leviathan.'
                          },
                          'name' => 'name',
                          'type' => 'semantic',
                          'href' => 'http://alps.io/schema.org/Text'
                        },
                        {"doc" => {"value" => "How large it is"},
                         "ext" => [{"value" => "{\"datalist\":\"size-list\"}", "href" => "http://alps.io/extensions/serialized_options_list"}],
                         "id" => "form-size",
                         "name" => "size",
                         "type" => "semantic",
                         "href" => "http://alps.io/schema.org/Text"},
                        {"doc" => {"value" => "How is the Leviathan."},
                         "ext" => [{"value" => "{\"hash\":{\"new\":\"new\",\"old\":\"old\"}}",
                                    "href" => "http://alps.io/extensions/serialized_options_list"}],
                         "id" => "form-status",
                         "name" => "status",
                         "type" => "semantic", "href" => "http://alps.io/schema.org/Text"}
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      }
    end

    def alps_xml
      @alps_xml ||= Nokogiri::XML(File.open(fixture_path('leviathans_alps.xml')))
    end

    def alps_xml_opened_file
      @alps_xml_string ||= File.open(fixture_path('leviathans_alps.xml'))
    end

    def alps_json_opened_file
      @alps_xml_string ||= File.open(alps_fixture_path('DRDs.json'))
    end

    def alps_xml_opened_file_with_bad_filename
      @alps_xml_string ||= File.open(alps_fixture_path('DRDs_x'))
    end

    def alps_json_opened_file_with_bad_filename
      @alps_xml_string ||= File.open(alps_fixture_path('DRDs_j'))
    end
  end

  module ALPSSchema
    AlpsInteger = <<-'HERE'
    <alps>
     <descriptor id="Integer" type="semantic" href="http://alps.io/schema.org/Number">
      <doc format="html">
       Data type: Integer.
      </doc>
     </descriptor>
    </alps>
    HERE

    AlpsArray = <<-'HERE'
    <alps>
     <descriptor id="Array" type="semantic" href="http://alps.io/schema.org/DataType">
      <doc format="html">
       Data type: Array.
      </doc>
     </descriptor>
    </alps>
    HERE

    AlpsText = <<-'HERE'
    <alps>
     <descriptor id="Text" type="semantic" href="http://alps.io/schema.org/DataType">
      <doc format="html">
       Data type: Text.
      </doc>
     </descriptor>
    </alps>
    HERE

    AlpsDateTime = <<-'HERE'
    <alps>
     <descriptor id="DateTime" type="semantic" href="http://alps.io/schema.org/DataType">
      <doc format="html">
       A combination of date and time of day in the form [-]CCYY-MM-DDThh:mm:ss[Z|(+|-)hh:mm] (see Chapter 5.4 of ISO 8601).
      </doc>
     </descriptor>
    </alps>
    HERE

    AlpsBoolean = <<-'HERE'
    <alps>
     <descriptor id="Boolean" type="semantic" href="http://alps.io/schema.org/DataType">
      <doc format="html">
       A combination of Boolean.
      </doc>
     </descriptor>
    </alps>
    HERE

    AlpsLeviathan = <<-'HERE'
    <alps>
     <descriptor id="Leviathan" type="semantic" href="http://alps.io/schema.org/DataType">
      <doc format="html">
       Data type: Leviathan.
      </doc>
     </descriptor>
    </alps>
    HERE

    AlpsDataType = <<-'HERE'
    <alps>
     <descriptor id="DataType" type="semantic">
      <doc format="html">
       The basic data types such as Integers, Strings, etc.
      </doc>
     </descriptor>
    </alps>
    HERE

    AlpsNumber = <<-'HERE'
    <alps>
     <descriptor id="Number" type="semantic" href="http://alps.io/schema.org/DataType">
      <doc format="html">
       Data type: Number.
      </doc>
     </descriptor>
    </alps>
    HERE

    StubUrls = {
      'http://alps.io/schema.org/Number' => AlpsNumber,
      'http://alps.io/schema.org/DataType' => AlpsDataType,
      'http://alps.io/schema.org/Integer' => AlpsInteger,
      'http://alps.io/schema.org/Text' => AlpsText,
      'http://alps.io/schema.org/Array' => AlpsArray,
      'http://alps.io/schema.org/DateTime' => AlpsDateTime,
      'http://alps.io/schema.org/Boolean' => AlpsBoolean,
      'http://alps.io/schema.org/Thing/Leviathan' => AlpsLeviathan
    }
  end

end
