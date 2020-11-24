//
//  LocalizableDSLTests.swift
//  LocalizableDSLTests
//
//  Created by Ruslan Alikhamov on 22.08.2020.
//

import XCTest
@testable import LocalizableDSL

class LocalizableDSLTests: XCTestCase {

    func fileData(name: String) -> Data {
        guard let fileURL = Bundle(for: type(of: self)).url(forResource: name, withExtension: "strings"), let file = try? Data(contentsOf: fileURL) else {
            fatalError("unable to locate Localizable.strings")
        }
        return file
    }
    
    func fileContent(name: String) -> String {
        let data = self.fileData(name: name)
        guard let retVal = String(data: data, encoding: .utf16) else {
            fatalError("unable to locate Localizable.strings")
        }
        return retVal
    }

    var singleLineInput : String {
        self.fileContent(name: "Localizable_single")
    }
    
    var multiLineInput : String {
        self.fileContent(name: "Localizable_multiple_same")
    }
    
    var multiLineSameInnerInput : String {
        self.fileContent(name: "Localizable_multiple_same_inner")
    }
    
    var multiLineSameAncestorSameInnerDifferentAncestorDifferentInnerDifferentOrderInput : String {
        self.fileContent(name: "Localizable_multiple_same_inner_different_outer")
    }
    
    var testParseMultilineSameAncestorSameAndDifferentInnerInput : String {
        self.fileContent(name: "Localizable_multiple_same_outer_different_inner")
    }
    
    var testMinimumInnerDifferentOuterInput : String {
        self.fileContent(name: "Localizable_minimum_inner_different_outer")
    }
    
    var testInnerSortingInput : String {
        self.fileContent(name: "Localizable_inner_sorting")
    }
    
    var testCommentsInvalidTokenInput : String {
        self.fileContent(name: "Localizable_comments_invalid_tokens")
    }
    
    var testNewNewInput : String {
        self.fileContent(name: "Localizable_test")
    }
    
    var testKeywordsEscapeInput : String {
        self.fileContent(name: "Localizable_keywords")
    }
    
    var testCommentsInput : String {
        self.fileContent(name: "Localizable_comments")
    }
    
    func testParserSingleLine() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.singleLineInput)
        XCTAssertEqual(output, """
        enum L {
          enum MyClass {
            enum TextLabel {
              static let text = NSLocalizedString("MyClass.textLabel.text", comment: "")
            }
          }
        }

        """)
    }
    
    func testParserMiltiLineSameAncestor() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.multiLineInput)
        XCTAssertEqual(output, """
        enum L {
          enum MyClass {
            enum PasswordLabel {
              static let text = NSLocalizedString("MyClass.passwordLabel.text", comment: "")
            }
            enum TextLabel {
              static let text = NSLocalizedString("MyClass.textLabel.text", comment: "")
            }
          }
        }

        """)
    }
    
    func testParserMiltiLineSameAncestorSameInnerEnum() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.multiLineSameInnerInput)
        XCTAssertEqual(output, """
        enum L {
          enum MyClass {
            enum Content {
              enum PasswordLabel {
                static let text = NSLocalizedString("MyClass.content.passwordLabel.text", comment: "")
              }
              enum TextLabel {
                static let text = NSLocalizedString("MyClass.content.textLabel.text", comment: "")
              }
            }
          }
        }

        """)
    }
    
    func testParseMultilineSameAncestorSameAndDifferentInner() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.testParseMultilineSameAncestorSameAndDifferentInnerInput)
        XCTAssertEqual(output,
        """
        enum L {
          enum ThirdClass {
            enum Content {
              enum LoginLabel {
                static let text = NSLocalizedString("ThirdClass.content.loginLabel.text", comment: "")
              }
              enum PasswordLabel {
                static let text = NSLocalizedString("ThirdClass.content.passwordLabel.text", comment: "")
              }
            }
            enum GeneralLabel {
              static let text = NSLocalizedString("ThirdClass.generalLabel.text", comment: "")
            }
          }
        }
        
        """)
    }
    
    func testParserMultilineSameAncestorSameInnerDifferentAncestorDifferentInnerDifferentOrder() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.multiLineSameAncestorSameInnerDifferentAncestorDifferentInnerDifferentOrderInput)
        XCTAssertEqual(output, """
        enum L {
          enum AnotherClass {
            enum Content {
              enum PasswordField {
                static let placeholder = NSLocalizedString(
                  "AnotherClass.content.passwordField.placeholder", comment: "")
              }
              enum TextLabel {
                static let text = NSLocalizedString("AnotherClass.content.textLabel.text", comment: "")
              }
            }
          }
          enum MyClass {
            enum Content {
              enum PasswordLabel {
                static let text = NSLocalizedString("MyClass.content.passwordLabel.text", comment: "")
              }
              enum TextLabel {
                static let text = NSLocalizedString("MyClass.content.textLabel.text", comment: "")
              }
            }
          }
          enum ThirdClass {
            enum Content {
              enum LoginLabel {
                static let text = NSLocalizedString("ThirdClass.content.loginLabel.text", comment: "")
              }
              enum PasswordLabel {
                static let text = NSLocalizedString("ThirdClass.content.passwordLabel.text", comment: "")
              }
            }
            enum GeneralLabel {
              static let text = NSLocalizedString("ThirdClass.generalLabel.text", comment: "")
            }
          }
        }

        """)
    }
    
    func testMinimumInnerDifferentOuter() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.testMinimumInnerDifferentOuterInput)
        XCTAssertEqual(output, """
        enum L {
          enum Blahblah {
            static let somethingNice = NSLocalizedString("blahblah.SomethingNice", comment: "")
          }
          enum Something {
            static let somethingSomewhere = NSLocalizedString("something.somethingSomewhere", comment: "")
          }
          enum Wherever {
            static let whenever = NSLocalizedString("wherever.whenever", comment: "")
            static let whoever = NSLocalizedString("wherever.whoever", comment: "")
          }
        }

        """)
    }
    
    func testInnerSorting() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.testInnerSortingInput)
        XCTAssertEqual(output, """
        enum L {
          enum AnotherClass {
            enum Content {
              enum TextLabel {
                static let text = NSLocalizedString("AnotherClass.content.textLabel.text", comment: "")
              }
            }
          }
          enum MyClass {
            enum Content {
              enum PasswordLabel {
                static let text = NSLocalizedString("MyClass.content.passwordLabel.text", comment: "")
              }
              enum TextLabel {
                static let text = NSLocalizedString("MyClass.content.textLabel.text", comment: "")
              }
            }
          }
        }

        """)
    }
    
    func testCommentsInvalidTokensNew() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.testCommentsInvalidTokenInput)
        XCTAssertEqual(output, """
        enum L {
          enum AnotherClass {
            enum Content {
              enum PasswordField {
                static let placeholder = NSLocalizedString(
                  "AnotherClass.content.passwordField.placeholder", comment: "")
              }
              enum TextLabel {
                static let text = NSLocalizedString("AnotherClass.content.textLabel.text", comment: "")
              }
            }
          }
          enum MyClass {
            enum Content {
              enum PasswordLabel {
                static let text = NSLocalizedString("MyClass.content.passwordLabel.text", comment: "")
              }
              enum TextLabel {
                static let text = NSLocalizedString("MyClass.content.textLabel.text", comment: "")
              }
            }
          }
          enum ThirdClass {
            enum Content {
              enum LoginLabel {
                static let text = NSLocalizedString("ThirdClass.content.loginLabel.text", comment: "")
              }
              enum PasswordLabel {
                static let text = NSLocalizedString("ThirdClass.content.passwordLabel.text", comment: "")
              }
            }
            enum GeneralLabel {
              static let text = NSLocalizedString("ThirdClass.generalLabel.text", comment: "")
            }
          }
        }

        """)
    }
    
    func testKeywordsEscape() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.testKeywordsEscapeInput)
        XCTAssertEqual(output, """
        enum L {
          enum Something {
            enum Another {
              static let subtitle = NSLocalizedString("something.another.subtitle", comment: "")
              enum Subtitle {
                static let one = NSLocalizedString("something.another.subtitle.1", comment: "")
                static let two = NSLocalizedString("something.another.subtitle.2", comment: "")
              }
              static let subtitle2 = NSLocalizedString("something.another.subtitle2", comment: "")
              static let title = NSLocalizedString("something.another.title", comment: "")
            }
            enum Random {
              enum Con {
                enum InvalidSymbolFound {
                  static let inue = NSLocalizedString("something.random.con@#$%inue`", comment: "")
                }
              }
              static let `continue` = NSLocalizedString("something.random.continue", comment: "")
              enum L_Type {
                static let `continue` = NSLocalizedString("something.random.type.continue`", comment: "")
              }
            }
          }
        }

        """)
    }
    
    func testComments() throws {
        let parser = DSL()
        let output = try parser.parse(input: self.testCommentsInput)
        XCTAssertEqual(output, """
        enum L {
          enum Hello {
            enum This {
              static let tag = NSLocalizedString("hello this is tag", comment: "")
            }
          }
          enum Something {
            enum Random {
              static let `continue` = NSLocalizedString(
                "something.random.continue", comment: "this is a comment")
            }
          }
        }

        """)
    }
    
}
