require 'spec_helper'

module Crichton
  describe 'ExternalDocumentStore' do
    context '.new' do
      it 'accepts a storage path' do
        pathname = 'test/path'
        Dir.should_receive(:exists?).with(pathname).and_return(true)
        ExternalDocumentStore.new(pathname)
      end

      it 'uses the configured storage path if none is explicitly passed into the new call' do
        pathname = 'test/path'
        Crichton.config.stub(:external_documents_store_directory).and_return(pathname)
        Dir.should_receive(:exists?).with(pathname).and_return(true)
        ExternalDocumentStore.new
      end

      it 'creates the storage path if it does not exist' do
        pathname = 'test/path'
        Dir.stub(:exists?).and_return(false)
        FileUtils.should_receive(:mkdir_p).with(pathname).and_return(true)
        ExternalDocumentStore.new(pathname)
      end
    end

    context '.get' do
      before do
        @pathname = 'pathname'
        Dir.should_receive(:exists?).and_return(true)
      end

      it 'reads the content of a file' do
        eds = ExternalDocumentStore.new(@pathname)
        File.stub(:exists?).and_return(true)
        file_obj = double('file')
        File.should_receive(:open).with('pathname/some_server_80_some_link.profile', 'rb').and_return(file_obj)
        eds.get('http://some.server/some_link')
      end

      it 'uses the pathname, hostname, port and path for the filename of the data file' do
        eds = ExternalDocumentStore.new(@pathname)
        File.stub(:exists?).and_return(true)
        file_obj = double('file')
        File.should_receive(:open).with('pathname/some_server_1234_some_link_down_.profile', 'rb').and_return(file_obj)
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
