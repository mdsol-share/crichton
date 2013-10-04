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
  end
end
