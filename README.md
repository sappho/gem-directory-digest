gem-directory-digest
--------------------

Creates a SHA256 digest of all of the files in a directory, and has simple directory comparison features.

Simple to use:

    require 'directory-digest/digest'
    digest = Digest.sha256('/opt/app')

Here `digest` is a `Digest` object which contains a SHA256 digest of the content of all of all of the files in the directory, and a hash of digests of each individual file.

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

This copies and deletes files in `/opt/app2` so that it ends up with the same content as `/opt/app1`. But note that directories are only created as needed and never deleted, so there might be empty directories in the destination after calling `mirror_from`.

It is possible to override the file operations by extending `MirrorActions`. See `spec/directory-digest/digest_spec.rb` for an example that logs each action to the console.

License
-------

This rubygem is distributed under the MIT license - see the LICENSE file in the root directory of the project.
