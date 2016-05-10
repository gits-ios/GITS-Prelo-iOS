import Foundation

struct Regex {
    var pattern: String {
        didSet {
            updateRegex()
        }
    }
    var expressionOptions: NSRegularExpressionOptions {
        didSet {
            updateRegex()
        }
    }
    var matchingOptions: NSMatchingOptions

    var regex: NSRegularExpression?

    init(pattern: String, expressionOptions: NSRegularExpressionOptions, matchingOptions: NSMatchingOptions) {
        self.pattern = pattern
        self.expressionOptions = expressionOptions
        self.matchingOptions = matchingOptions
        updateRegex()
    }

    init(pattern: String) {
        self.pattern = pattern
        expressionOptions = NSRegularExpressionOptions(rawValue: 0)
        matchingOptions = NSMatchingOptions(rawValue: 0)
        updateRegex()
    }

    mutating func updateRegex() {
        do {
            regex = try NSRegularExpression(pattern: pattern, options: expressionOptions)
        } catch
        {
            
        }
    }
}


extension String {
    func matchRegex(pattern: Regex) -> Bool {
        let range: NSRange = NSMakeRange(0, self.length)
        if pattern.regex != nil {
            let matches: [AnyObject] = pattern.regex!.matchesInString(self, options: pattern.matchingOptions, range: range)
            return matches.count > 0
        }
        return false
    }

    func match(patternString: String) -> Bool {
        return self.matchRegex(Regex(pattern: patternString))
    }

    func replaceRegex(pattern: Regex, template: String) -> String {
        if self.matchRegex(pattern) {
            let range: NSRange = NSMakeRange(0, self.length)
            if pattern.regex != nil {
                return pattern.regex!.stringByReplacingMatchesInString(self, options: pattern.matchingOptions, range: range, withTemplate: template)
            }
        }
        return self
    }

    func replace(pattern: String, template: String) -> String {
        return self.replaceRegex(Regex(pattern: pattern), template: template)
    }
}
/*
//e.g. replaces symbols +, -, space, ( & ) from phone numbers
"+91-999-929-5395".replace("[-\\s\\(\\)]", template: "")

*/
