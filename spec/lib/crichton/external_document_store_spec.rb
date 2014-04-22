require 'spec_helper'
require 'crichton/external_document_store'

module Crichton
  describe ExternalDocumentStore do
    def datafile_path(path, link)
      url = URI.parse(link)
      host_port_and_path = "#{url.host}:#{url.port.to_s}#{url.path}"
      snaked_host_port_and_path = host_port_and_path.gsub(/\W/, '_')
      File.join(path, "#{snaked_host_port_and_path}.profile")
    end

    def metafile_path(path, link)
      url = URI.parse(link)
      host_port_and_path = "#{url.host}:#{url.port.to_s}#{url.path}"
      snaked_host_port_and_path = host_port_and_path.gsub(/\W/, '_')
      File.join(path, "#{snaked_host_port_and_path}.meta")
    end

    describe '.new' do
      before do
        @pathname = 'test/path'
      end

      it 'accepts a storage path' do
        Dir.should_receive(:exists?).with(@pathname).and_return(true)
        ExternalDocumentStore.new(@pathname)
      end

      it 'uses the configured storage path if none is explicitly passed into the new call' do
        Crichton.config.stub(:external_documents_store_directory).and_return(@pathname)
        Dir.should_receive(:exists?).with(@pathname).and_return(true)
        ExternalDocumentStore.new
      end

      it 'uses the supplied storage path if it is explicitly passed into the new call' do
        overridden_pathname = 'overridden/path'
        Crichton.config.stub(:external_documents_store_directory).and_return(@pathname)
        Dir.should_receive(:exists?).with(overridden_pathname).and_return(true)
        ExternalDocumentStore.new(overridden_pathname)
      end

      it 'creates the storage path if it does not exist' do
        Dir.stub(:exists?).and_return(false)
        FileUtils.should_receive(:mkdir_p).with(@pathname).and_return(true)
        ExternalDocumentStore.new(@pathname)
      end
    end

    describe '#get' do
      before do
        @pathname = 'pathname'
        Dir.stub(:exists?).and_return(true)
      end

      it 'reads the content of a file' do
        eds = ExternalDocumentStore.new(@pathname)
        File.stub(:exists?).and_return(true)
        File.should_receive(:open).with('pathname/some_server_80_some_link.profile', 'rb').and_return(double('file'))
        eds.get('http://some.server/some_link')
      end

      it 'uses the pathname, hostname, port and path for the filename of the data file' do
        eds = ExternalDocumentStore.new(@pathname)
        File.stub(:exists?).and_return(true)
        File.should_receive(:open).with('pathname/some_server_1234_some_link_down_.profile', 'rb').and_return(double('file'))
        eds.get('http://some.server:1234/some_link/down/')
      end

      it 'returns nil if the file does not exist' do
        eds = ExternalDocumentStore.new(@pathname)
        File.stub(:exists?).and_return(false)
        eds.get('http://some.server/some_link').should == nil
      end
    end

    describe '.download_link_and_store_in_document_store' do
      before do
        @body = 'somebody'
        @link = 'http://hostname:80/path/to/somewhere'
        @request = stub_request(:get, @link).to_return(status: 200, body: @body, headers: {})
      end

      it 'downloads the provided URL' do
        @pathname = 'pathname'
        Crichton::ExternalDocumentStore.new(@pahname).download_link_and_store_in_document_store(@link)
        @request.should have_been_made
      end

      context '.write_data_to_store' do
        before do
          @pathname = File.join('spec', 'fixtures', 'external_documents_store')
          FileUtils.mkdir_p(@pathname) unless Dir.exists?(@pathname)
          @datafilename = File.join(@pathname, 'hostname_80_path_to_somewhere.profile')
          @metafilename = File.join(@pathname, 'hostname_80_path_to_somewhere.meta')
          File.delete(@datafilename) if File.exist?(@datafilename)
          File.delete(@metafilename) if File.exist?(@metafilename)
        end

        it 'writes the deta file' do
          eds = ExternalDocumentStore.new(@pathname)
          eds.download_link_and_store_in_document_store(@link)
          File.open(@datafilename, 'rb') { |f| f.read}.should == @body
        end

        it 'writes the meta file' do
          eds = ExternalDocumentStore.new(@pathname)
          eds.download_link_and_store_in_document_store(@link)
          File.open(@metafilename, 'rb') { |f| f.read}.should == 'http://hostname:80/path/to/somewhere'
        end
      end
    end

    describe '.compare_stored_documents_with_their_original_documents' do
      before do
        @pathname = File.join('spec', 'fixtures', 'external_documents_store')
        FileUtils.mkdir_p(@pathname) unless Dir.exists?(@pathname)
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
        @fixturelist = %w(test1 test2 test3)
        @fixturelist.each do |fn|
          link = "http://www.#{fn}.com/#{fn}"
          File.open(File.join(metafile_path(@pathname, link)), 'wb') { |f| f.write(link) }
          File.open(File.join(datafile_path(@pathname, link)), 'wb') { |f| f.write("#{fn}\n") }
        end
      end

      after do
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
      end

      it 'makes a request to every link it finds a file for' do
        request = stub_request(:get, /^http:\/\/www\.test.\.com\/test.$/).
            to_return(status: 200, body: "testX\n", headers: {})
        eds = ExternalDocumentStore.new(@pathname)
        eds.compare_stored_documents_with_their_original_documents
        request.should have_been_made.times(3)
      end

      it 'complains about changed file content' do
        @requests = {}
        @fixturelist.each do |fn|
          link = "http://www.#{fn}.com/#{fn}"
          @requests[fn] = stub_request(:get, link).to_return(status: 200, body: "#{fn}\n", headers: {})
        end
        eds = ExternalDocumentStore.new(@pathname)
        link = "http://www.#{@requests.keys.first}.com/#{@requests.keys.first}"
        File.open(File.join(datafile_path(@pathname, link)), 'wb') do |f|
          f.write("X#{@requests.keys.first}\n")
        end
        eds.compare_stored_documents_with_their_original_documents.should ==
            "Data of link http://www.test1.com/test1 has changed!\n-Xtest1\n+test1\n"
      end
    end

    describe '.store_all_external_documents' do
      before do
        Crichton.stub(:descriptor_location).and_return(resource_descriptor_fixtures)
        @pathname = File.join('spec', 'fixtures', 'external_documents_store')
        Support::ALPSSchema::StubUrls.each do |url, body|
          stub_request(:get, url).to_return(:status => 200, :body => body, :headers => {})
        end
        FileUtils.mkdir_p(@pathname) unless Dir.exists?(@pathname)
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
        FileUtils.rm Dir.glob(File.join(@pathname, '*.profile'))
      end

      after do
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
        FileUtils.rm Dir.glob(File.join(@pathname, '*.profile'))
      end

      it 'loads external documents', :pending do
        eds = ExternalDocumentStore.new(@pathname)
        eds.store_all_external_documents
        files = Dir.glob(File.join([@pathname, '*'])).collect {|f| f.split('schema_org_').last}
        files.sort.should == %w(Array.meta Array.profile Boolean.meta Boolean.profile DateTime.meta DateTime.profile
          Integer.meta Integer.profile Text.meta Text.profile Thing_Leviathan.meta Thing_Leviathan.profile).sort
      end
    end
  end
end
