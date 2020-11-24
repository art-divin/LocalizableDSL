# LocalizableDSL
Implementation of Localizables.string to Swift enum conversion

# How to Build
LocalizableDSL framework depends on:
- SwiftSyntax (https://github.com/apple/swift-syntax)
- SwiftFormat (https://github.com/apple/swift-format)
- lib_InternalSwiftSyntaxParser.dylib

# Setup Dependencies

## SwiftSyntax
1. git clone -b swift-5.2-branch https://github.com/apple/swift-syntax
2. cd swift-syntax
3. swift package generate-xcodeproj
4. drag & drop generated SwiftSyntax.xcodeproj to LocalizableDSL project navigator as a dependency (replacing existing missing one)

## SwiftFormat
1. git clone -b swift-5.2-branch https://github.com/apple/swift-format
2. cd swift-format
3. swift package generate-xcodeproj
4. drag & drop generated swift-format.xcodeproj to LocalizableDSL project navigator as a dependency (replacing existing missing one)

## lib_InternalSwiftSyntaxParser.dylib
To quote from https://github.com/apple/swift-syntax:

> Embedding SwiftSyntax in an Application

> SwiftSyntax depends on the lib_InternalSwiftSyntaxParser.dylib/.so library which provides a C interface to the underlying Swift C++ parser. When you do swift build SwiftSyntax links and uses the library included in the Swift toolchain. If you are building an application make sure to embed _InternalSwiftSyntaxParser as part of your application's libraries.

So, in order to add lib_InternalSwiftSyntaxParser.dylib as a dependency, search in Finder for "lib_InternalSwiftSyntaxParser.dylib" and drag & drop (or better copy) found dylib into LocalizableDSL directory, then, drag & drop lib_InternalSwiftSyntaxParser.dylib into LocalizableDSL project navigator (replacing existing missing one)

# Examples
LocalizableDSL provides public API:
```lang=swift
public class DSL {
    public init()
    public func parse(input: String) throws -> String
}
```

## Usage
```lang=swift
let parser = DSL()
let output = try parser.parse(input: "\"MyClass.textLabel.text\" = \"hello there\";")
print(output)
// prints
enum L {
  enum MyClass {
    enum TextLabel {
      static let text = NSLocalizedString("MyClass.textLabel.text", comment: "")
    }
  }
}
```
