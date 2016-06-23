gem-directory-digest
--------------------

Creates a SHA256 digest of all of the files in a directory, and has simple directory comparison and mirroring features.

Simple to use:

    require 'directory-digest/digest'
    digest = Digest.sha256('/opt/app')

Here `digest` is a `Digest` object which contains a SHA256 digest of the content of all of all of the files in the directory, and a hash of digests of each individual file.

By default, all files in a directory and it's sub-directories are added to the digest. To apply a simple filter use something like this:

    digest = Digest.sha256('/opt/app', '**/*.rb')

More complex filtering can be applied by adding a third parameter that can be either a proc or a string array, as in these examples:

    digest1 = Digest.sha256('/opt/app', '**/*', -> { |path| path =~ /test/ })
    digest2 = Digest.sha256('/opt/app', '**/*', %w(-. +test))

Both of these will produce equal digests. The first variant includes any file that has `test` anywhere in the file's path. The second variant applies each regex string (minus the first character) in turn to each file's path and uses the first character of the regex string to determine if the file is included (plus sign) or excluded (minus sign).

You can compare directories, to check for identical content, like this:

    digest1 = Digest.sha256('/opt/app1')
    digest2 = Digest.sha256('/opt/app2')
    digest1 == digest2

Or, to check for differences:

    digest1 != digest2

A report of the differences between two directories can be had with:

    digest2.changes_relative_to(digest1)

This will return a hash that looks like this:

    {
        added: {
            '/folder-2/test-2.txt': 'a21e7aa4fe2cac1ec6b14a0e99f7d3be23fe6f1552e4ccd5b7e2e23e35f7f860'
        },
        removed: { ... },
        changed: { ... },
        unchanged: { ... }
    }

Each of the four top level keys contain a hash of the files, and their digests, that fall into that category.

To mirror one directory to another, both of which must exist beforehand, do this:

    digest2.mirror_from(digest1)

This copies and deletes files in `/opt/app2` so that it ends up with the same file content as `/opt/app1`. Note that directories are only created as needed and never deleted, so there might be empty directories in the destination after calling `mirror_from`. Also note that only the files listed in the digest are copied or deleted, so if the digest was filtered then the source and destination directories may not end up being equal as such. The goal is to synchronize the files in the digest only.

It is possible to override the file operations by extending `MirrorActions`. See `spec/directory-digest/digest_spec.rb` for an example that logs each action to the console.

License
-------

This rubygem is distributed under the MIT license - see the `LICENSE` file in the root directory of the project.
