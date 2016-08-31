require 'openssl'
require 'json'
require 'fileutils'

module DirectoryDigest
  # DirectoryDigest::Digest - Creates a SHA256 digest of a directory's content.
  class Digest
    attr_reader :directory
    attr_reader :directory_digest
    attr_reader :file_digests
    attr_reader :files_excluded

    def initialize(directory, directory_digest, file_digests, files_excluded)
      @directory = directory.freeze
      @directory_digest = directory_digest.freeze
      @file_digests = file_digests.freeze
      @files_excluded = files_excluded.freeze
    end

    def self.sha256(directory, glob = '**/*', include = proc { true })
      if include.is_a?(Array)
        regex_list = include
        include = lambda do |path|
          matches = regex_list.select { |regex| regex.size > 1 && path =~ /#{regex[1..-1]}/ }
          matches.count.zero? || matches.last[0] == '+'
        end
      end
      directory_digest = OpenSSL::Digest::SHA256.new
      file_digests = {}
      files_excluded = []
      Dir["#{directory}/#{glob}"].each do |filename|
        next unless File.file?(filename)
        path = filename[directory.size..-1]
        if include.call(path)
          file_digest = OpenSSL::Digest::SHA256.new
          File.open(filename, 'rb') do |file|
            until file.eof?
              chunk = file.read(4096)
              directory_digest << chunk
              file_digest << chunk
            end
          end
          file_digests[path] = file_digest.hexdigest
        else
          files_excluded << path
        end
      end
      Digest.new(directory, directory_digest.hexdigest, file_digests, files_excluded)
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
        unchanged: other.file_digests.select { |path, digest| file_digests.key?(path) && digest == file_digests[path] },
        excluded: files_excluded | other.files_excluded
      }
    end

    def mirror_from(other, actions = MirrorActions.new)
      changes = changes_relative_to(other)
      to_copy = changes[:removed].merge(changes[:changed])
      to_copy.keys.each do |path|
        source_path = "#{other.directory}#{path}"
        destination_path = "#{directory}#{path}"
        destination_directory = File.dirname(destination_path)
        actions.create_directory(destination_directory) unless Dir.exist?(destination_directory)
        actions.copy_file(source_path, destination_path)
      end
      to_delete = changes[:added]
      to_delete.keys.each do |path|
        actions.delete_file("#{directory}#{path}")
      end
      {
        copied: to_copy,
        deleted: to_delete,
        unchanged: changes[:unchanged],
        excluded: changes[:excluded]
      }
    end

    def to_json
      JSON.pretty_generate(directory: directory,
                           directory_digest: directory_digest,
                           file_digests: file_digests,
                           files_excluded: files_excluded)
    end

    def self.from_json(json)
      json = JSON.parse(json)
      Digest.new(json['directory'],
                 json['directory_digest'],
                 json['file_digests'],
                 json['files_excluded'])
    end
  end

  # DirectoryDigest::MirrorActions - Provider for standard mirror making activities.
  class MirrorActions
    def initialize(chunk_size = 4096)
      @chunk_size = chunk_size
    end

    def create_directory(directory)
      FileUtils.makedirs(directory)
    end

    def copy_file(source, destination)
      File.open(source, 'rb') do |source_file|
        File.open(destination, 'wb') do |destination_file|
          destination_file.write(source_file.read(@chunk_size)) until source_file.eof?
        end
      end
    end

    def delete_file(filename)
      File.delete(filename)
    end
  end
end
