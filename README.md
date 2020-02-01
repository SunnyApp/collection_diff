# collection_diff


[![pub package](https://img.shields.io/pub/v/collection_diff.svg)](https://pub.dartlang.org/packages/collection_diff)
[![Coverage Status](https://coveralls.io/repos/pgithub/SunnyApp/collection_diff/badge.svg?branch=master)](https://coveralls.io/github/SunnyApp/collection_diff?branch=master)


A flutter project that compares two collections and produces a list of deltas between then.  This
is useful when working with flutter's [AnimatedList](https://flutter.dev/docs/catalog/samples/animated-list)
widgets, or any other time you want to respond to list changes without having to rebuild your entire
view.

By default, the diffs run synchronously, which hurts performance if you run them in the main thread.  
See the [collection_diff_isolate] package for running the diff operations in the background.

