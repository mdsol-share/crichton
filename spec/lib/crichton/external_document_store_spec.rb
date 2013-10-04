require 'spec_helper'
require 'crichton/external_document_store'

module Crichton
  describe ExternalDocumentStore do
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

    context '.download' do
      before do
        @pathname = 'pathname'
        @response = double('Response')
        @response.stub(:body).and_return('data')
      end

      it 'calls HTTP.start with the URL' do
        Net::HTTP.should_receive(:start).with('hostname', 80).and_return(@response)
        eds = ExternalDocumentStore.new(@pathname)
        eds.download('http://hostname:80')
      end

      it 'returns the response body' do
        Net::HTTP.stub(:start).and_return(@response)
        eds = ExternalDocumentStore.new(@pathname)
        eds.download('http://hostname:80').should == 'data'
      end
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
        eds.write_data_to_store('http://hostname:80/path/to/somewhere', 'testdata')
        File.open(@datafilename, 'rb') { |f| f.read}.should == 'testdata'
      end

      it 'writes the meta file' do
        eds = ExternalDocumentStore.new(@pathname)
        eds.write_data_to_store('http://hostname:80/path/to/somewhere', 'testdata')
        File.open(@metafilename, 'rb') { |f| f.read}.should == 'http://hostname:80/path/to/somewhere'
      end
    end

    context '.get_list_of_stored_links' do
      before do
        @pathname = File.join('spec', 'fixtures', 'external_documents_store')
        FileUtils.mkdir_p(@pathname) unless Dir.exists?(@pathname)
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
        @fixturelist = %w(test1 test2 test3)
        @fixturelist.each { |fn| File.open(File.join(@pathname, "#{fn}.meta"), 'wb') { |f| f.write("Link #{fn}") }}
      end

      it 'returns a list of links (the content of the .meta files)' do
        eds = ExternalDocumentStore.new(@pathname)
        eds.get_list_of_stored_links.should == @fixturelist.map { |fn| "Link #{fn}" }
      end

      after do
        FileUtils.rm Dir.glob(File.join(@pathname, '*.meta'))
      end
    end
  end
end
