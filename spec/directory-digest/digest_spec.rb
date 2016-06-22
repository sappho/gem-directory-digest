require 'spec_helper'
require 'fileutils'
require 'directory-digest/digest'

module DirectoryDigest
  describe Digest do
    describe '.sha256' do
      it 'creates a SHA256 digest of all the files in a directory' do
        digest = Digest.sha256('spec/test-data/data')
        expect(digest.directory_digest).to eq '515613f6a36f6d313c99db44fe96c019ec729474fa53d44ab2a13b3eea09634b'
        expect(digest.file_digests.count).to eq 4
        expect(digest.file_digests['/test-4096.bin'])
          .to eq '792524edd412193c9d2e53734a5e95ee67fc3e502e64dc6f8e2ea53e87d30ad8'
        expect(digest.file_digests['/test-5000.bin'])
          .to eq '767049956dd3ece3d24398c6a63d9ed94fa6de06fb0722bfa0983f904d942bd4'
        expect(digest.file_digests['/test-1.txt'])
          .to eq 'e4314adaaaec5fd9392651f770d132f5eda6b104ed371d5ac5bbc8cb30e87fba'
        expect(digest.file_digests['/folder/test-2.txt'])
          .to eq 'f8a53856c16ad36fb467877e41aba60bedf48ee5206cbfb704c0d0b6e8358ffb'
      end

      it 'creates a SHA256 digest of some of the files in a directory (with an exclude)' do
        digest = Digest.sha256('spec/test-data/data', '**/*', ['-\.txt$'])
        expect(digest.directory_digest).to eq '07076f7ddd861e2ef6b0510b6d8f08cfcc409380e90ecc2a3070b42db356305c'
        expect(digest.file_digests.count).to eq 2
        expect(digest.file_digests['/test-4096.bin'])
          .to eq '792524edd412193c9d2e53734a5e95ee67fc3e502e64dc6f8e2ea53e87d30ad8'
        expect(digest.file_digests['/test-5000.bin'])
          .to eq '767049956dd3ece3d24398c6a63d9ed94fa6de06fb0722bfa0983f904d942bd4'
      end

      it 'creates a SHA256 digest of some of the files in a directory (with an exclude and cancelling include)' do
        digest = Digest.sha256('spec/test-data/data', '**/*', ['-.*', '+\.bin$'])
        expect(digest.directory_digest).to eq '07076f7ddd861e2ef6b0510b6d8f08cfcc409380e90ecc2a3070b42db356305c'
        expect(digest.file_digests.count).to eq 2
        expect(digest.file_digests['/test-4096.bin'])
          .to eq '792524edd412193c9d2e53734a5e95ee67fc3e502e64dc6f8e2ea53e87d30ad8'
        expect(digest.file_digests['/test-5000.bin'])
          .to eq '767049956dd3ece3d24398c6a63d9ed94fa6de06fb0722bfa0983f904d942bd4'
      end
    end

    describe '#==' do
      it 'can spot equality of two directories' do
        first_digest = Digest.sha256('spec/test-data/data')
        second_digest = Digest.sha256('spec/test-data/data')
        expect(first_digest == second_digest).to eq true
      end
    end

    describe '#!=' do
      it 'can spot inequality of two directories' do
        first_digest = Digest.sha256('spec/test-data/data')
        second_digest = Digest.sha256('spec/test-data/alt-data')
        expect(first_digest != second_digest).to eq true
      end
    end

    describe '#changes_relative_to' do
      it 'creates a valid report on the differences between directories' do
        first_digest = Digest.sha256('spec/test-data/alt-data')
        second_digest = Digest.sha256('spec/test-data/data')
        differences = first_digest.changes_relative_to(second_digest)
        expect(differences.count).to eq 4
        expect(differences[:added].count).to eq 1
        expect(differences[:removed].count).to eq 1
        expect(differences[:changed].count).to eq 1
        expect(differences[:unchanged].count).to eq 2
      end

      it 'creates a valid report on the lack of differences between directories' do
        first_digest = Digest.sha256('spec/test-data/data')
        second_digest = Digest.sha256('spec/test-data/data')
        differences = first_digest.changes_relative_to(second_digest)
        expect(differences.count).to eq 4
        expect(differences[:added].count).to eq 0
        expect(differences[:removed].count).to eq 0
        expect(differences[:changed].count).to eq 0
        expect(differences[:unchanged].count).to eq 4
      end
    end

    describe '#mirror_from' do
      it 'mirrors files correctly' do
        FileUtils.makedirs('test')
        first_digest = Digest.sha256('spec/test-data/data')
        second_digest = Digest.sha256('test')
        second_digest.mirror_from(first_digest, LogMirrorActions.new)
        second_digest = Digest.sha256('test')
        expect(first_digest == second_digest).to eq true
        first_digest = Digest.sha256('spec/test-data/alt-data')
        second_digest.mirror_from(first_digest, LogMirrorActions.new)
        second_digest = Digest.sha256('test')
        expect(first_digest == second_digest).to eq true
        first_digest = Digest.sha256('spec/test-data/empty')
        second_digest.mirror_from(first_digest, LogMirrorActions.new)
        second_digest = Digest.sha256('test')
        expect(first_digest == second_digest).to eq true
      end
    end

    describe '#to_json' do
      it 'returns valid JSON' do
        digest = Digest.sha256('spec/test-data/data')
        expect(digest.to_json).to match(/^{.*?e4314adaaaec5fd9392651f770d132f5eda6b104ed371d5ac5bbc8cb30e87fba.*}$/m)
      end
    end

    describe '.from_json' do
      it 'parses valid JSON' do
        json = {
          directory: '/opt/test',
          directory_digest: '515613f6a36f6d313c99db44fe96c019ec729474fa53d44ab2a13b3eea09634b',
          file_digests: {
            '/test-path' => '792524edd412193c9d2e53734a5e95ee67fc3e502e64dc6f8e2ea53e87d30ad8'
          }
        }.to_json
        digest = Digest.from_json(json)
        expect(digest.directory).to eq '/opt/test'
        expect(digest.directory_digest).to eq '515613f6a36f6d313c99db44fe96c019ec729474fa53d44ab2a13b3eea09634b'
        expect(digest.file_digests.count).to eq 1
        expect(digest.file_digests['/test-path'])
          .to eq '792524edd412193c9d2e53734a5e95ee67fc3e502e64dc6f8e2ea53e87d30ad8'
      end
    end
  end

  class LogMirrorActions < MirrorActions
    def create_directory(directory)
      puts "creating directory #{directory}"
      super(directory)
    end

    def copy_file(source, destination)
      puts "copying #{source} to #{destination}"
      super(source, destination)
    end

    def delete_file(filename)
      puts "deleting #{filename}"
      super(filename)
    end
  end
end
