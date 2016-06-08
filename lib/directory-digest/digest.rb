require 'openssl'
require 'json'

module DirectoryDigest
  # DirectoryDigest::Digest - Creates a SHA256 digest of a directory's content
  class Digest
    attr_reader :directory_digest
    attr_reader :file_digests

    def initialize(directory_digest, file_digests)
      @directory_digest = directory_digest
      @file_digests = file_digests
    end

    def self.sha256(directory, glob = '**/*', includes = [])
      directory_digest = OpenSSL::Digest::SHA256.new
      file_digests = {}
      Dir["#{directory}/#{glob}"].each do |filename|
        next unless File.file?(filename)
        path = filename[directory.size, 99_999]
        included = true
        includes.each do |include|
          included = include[0] == '+' if include.size > 1 && path =~ /#{include[1, 99_999]}/i
        end
        next unless included
        file_digest = OpenSSL::Digest::SHA256.new
        File.open(filename, 'rb') do |file|
          until file.eof?
            chunk = file.read(4096)
            directory_digest << chunk
            file_digest << chunk
          end
        end
        file_digests[path] = file_digest.hexdigest
      end
      Digest.new(directory_digest.hexdigest, file_digests)
    end

    def ==(other)
      directory_digest == other.directory_digest
    end

    def !=(other)
      directory_digest != other.directory_digest
    end

    def changes_relative_to(other)
      {
        added: file_digests.select { |path, _| !other.file_digests.key?(path) },
        removed: other.file_digests.select { |path, _| !file_digests.key?(path) },
        changed: other.file_digests.select { |path, digest| file_digests.key?(path) && digest != file_digests[path] },
        unchanged: other.file_digests.select { |path, digest| file_digests.key?(path) && digest == file_digests[path] }
      }
    end

    def to_json
      JSON.pretty_generate(directory_digest: directory_digest, file_digests: file_digests)
    end

    def self.from_json(json)
      json = JSON.parse(json)
      Digest.new(json['directory_digest'], json['file_digests'])
    end
  end
end
