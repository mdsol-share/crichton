module Support
  module ALPS
    def alps_profile
      {
        'alps' => {
          'doc' => {
            'value' => 'Describes Leviathans.'
          },
          'ext' => [
            {'href' => 'alps_base/Leviathans#leviathan/alt', 'value' => 'Alternate.'}
          ],
          'link' => [
            {
              'rel' => 'self', 
              'href' => 'alps_base/Leviathans'
            }, 
            {
              'rel' => 'help', 
              'href' => 'documentation_base/Things/Leviathans'
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
                  'href' => 'alps_base/Leviathans#leviathan/note', 
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
                          'href' => 'alps_base/Leviathans#leviatahn/create/create-leviathan'
                        },
                        {
                          'rel' => 'help',
                          'href' => 'documentation_base/Forms/create-leviathan'
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
  end
end
