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

      after do
        Dir.rmdir(@pathname) if Dir.exists?(@pathname)
      end

      it 'accepts a storage path' do
        # I dont understand this test or this testing strategy, why tie so closely to the internals
        # of the method?  Why are we not checking
        ExternalDocumentStore.new(@pathname)
        expect(Dir.exists?(@pathname)).to be true
      end

      it 'uses the configured storage path if none is explicitly passed into the new call' do
        allow(Crichton.config).to receive(:external_documents_store_directory).and_return(@pathname)
        ExternalDocumentStore.new
        expect(Dir.exists?(@pathname)).to be true
      end

      it 'uses the supplied storage path if it is explicitly passed into the new call' do
        @pathname = 'overridden/path'
        ExternalDocumentStore.new(@pathname)
        expect(Dir.exists?(@pathname)).to be true
      end

      it 'creates the storage path if it does not exist' do
        expect(Dir.exists?(@pathname)).to be false
        ExternalDocumentStore.new(@pathname)
        expect(Dir).to exist(@pathname)
      end
    end

    describe '#get' do
      before do
        @pathname = 'pathname'
        allow(Dir).to receive(:exists?).and_return(true)
      end

      it 'reads the content of a file' do
        eds = ExternalDocumentStore.new(@pathname)
        allow(File).to receive(:exists?).and_return(true)
        expect(File).to receive(:open).with('pathname/some_server_80_some_link.profile', 'rb').and_return(double('file'))
        eds.get('http://some.server/some_link')
      end

      it 'uses the pathname, hostname, port and path for the filename of the data file' do
        eds = ExternalDocumentStore.new(@pathname)
        allow(File).to receive(:exists?).and_return(true)
        expect(File).to receive(:open).with('pathname/some_server_1234_some_link_down_.profile', 'rb').and_return(double('file'))
        eds.get('http://some.server:1234/some_link/down/')
      end

      it 'returns nil if the file does not exist' do
        eds = ExternalDocumentStore.new(@pathname)
        allow(File).to receive(:exists?).and_return(false)
        expect(eds.get('http://some.server/some_link')).to eq(nil)
      end
    end

    describe '.download_link_and_store_in_document_store' do
      before do
        @body = 'somebody'
        @link = 'http://hostname:80/path/to/somewhere'
        @request = stub_request(:get, @link).to_return(status: 200, body: @body, headers: {})
        @doc_store = Crichton::ExternalDocumentStore.new('pathname')
      end

      it 'downloads the provided URL' do
        @doc_store.download_link_and_store_in_document_store(@link)
        expect(@request).to have_been_made
      end

      it 'detects outdated documents and prompts for overwrite' do
        expect(@doc_store).to receive(:get).and_return('another body')
        expect(STDIN).to receive(:gets).and_return('y')
        expect(@doc_store).to receive(:write_data_to_store)
        @doc_store.download_link_and_store_in_document_store(@link)
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
          expect(File.open(@datafilename, 'rb') { |f| f.read}).to eq(@body)
        end

        it 'writes the meta file' do
          eds = ExternalDocumentStore.new(@pathname)
          eds.download_link_and_store_in_document_store(@link)
          expect(File.open(@metafilename, 'rb') { |f| f.read}).to eq('http://hostname:80/path/to/somewhere')
        end
      end
    end

    describe '.compare_stored_documents_with_original' do
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
        @eds = ExternalDocumentStore.new(@pathname)
      end

      after do
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
      end

      it 'makes a request to every link it finds a file for' do
        request = stub_request(:get, /^http:\/\/www\.test.\.com\/test.$/).
            to_return(status: 200, body: "testX\n", headers: {})
        @eds.compare_stored_documents_with_original
        expect(request).to have_been_made.times(3)
      end

      it 'complains about changed file content' do
        @requests = {}
        @fixturelist.each do |fn|
          link = "http://www.#{fn}.com/#{fn}"
          @requests[fn] = stub_request(:get, link).to_return(status: 200, body: "#{fn}\n", headers: {})
        end
        link = "http://www.#{@requests.keys.first}.com/#{@requests.keys.first}"
        File.open(File.join(datafile_path(@pathname, link)), 'wb') do |f|
          f.write("X#{@requests.keys.first}\n")
        end
        expect(@eds.compare_stored_documents_with_original).to eq(
            "Data of link http://www.test1.com/test1 has changed!\n-Xtest1\n+test1\n"
        )
      end

      it 'reports non 200 response status' do
        request = stub_request(:get, /^http:\/\/www\.test.\.com\/test.$/).
            to_return(status: 404, body: "Not found\n", headers: {})
        expect(@eds.compare_stored_documents_with_original).to include(
            "Retrieving link http://www.test1.com/test1 resulted in HTTP code 404\n"
        )
      end
    end

    describe '.store_all_external_documents' do
      before do
        allow(Crichton).to receive(:descriptor_location).and_return(resource_descriptor_fixtures)
        @pathname = File.join('spec', 'fixtures', 'external_documents_store')
        Support::ALPSSchema::StubUrls.each do |url, body|
          stub_request(:get, url).to_return(:status => 200, :body => body, :headers => {})
        end
        stub_request(:get, "http://example.org/profiles/ErrorCodes").
          to_return(:status => 200, :body => "An arbitrary body", :headers => {})
        FileUtils.mkdir_p(@pathname) unless Dir.exists?(@pathname)
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
        FileUtils.rm Dir.glob(File.join(@pathname, '*.profile'))
      end

      after do
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
        FileUtils.rm Dir.glob(File.join(@pathname, '*.profile'))
      end

      it 'loads external documents' do
        eds = ExternalDocumentStore.new(@pathname)
        eds.store_all_external_documents
        expect(eds.compare_stored_documents_with_original).to eq("")
      end
    end
  end
end
