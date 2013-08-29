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
            {'href' => 'http://alps.example.com/Leviathans#alt', 'value' => 'Alternate.'}
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

    def alps_xml
      @alps_xml ||= Nokogiri::XML(File.open(fixture_path('leviathans_alps.xml')))
    end

    def alps_xml_string
      @alps_xml_string ||= File.open(fixture_path('leviathans_alps.xml'))
    end
  end
end
