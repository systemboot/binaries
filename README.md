# binaries
Binaries and build scripts for non-Go components for Systemboot

## How to release

Make your changes and tag them with the release number (e.g. v0.7, check the
existing tags to see what should be the next).
Once the code is merged, the release will be automatically generated.

If the code is already committed and you want to create a new release, creating
and pushing a new tag will still trigger the build and release. Just run:

* git tag $TAG_NAME
* git push --tags

Then wait for Travis-CI to build it at https://travis-ci.org/github/systemboot/binaries

