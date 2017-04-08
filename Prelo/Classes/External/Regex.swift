import Foundation

struct Regex {
    var pattern: String {
        didSet {
            updateRegex()
        }
    }
    var expressionOptions: NSRegularExpression.Options {
        didSet {
            updateRegex()
        }
    }
    var matchingOptions: NSRegularExpression.MatchingOptions

    var regex: NSRegularExpression?

    init(pattern: String, expressionOptions: NSRegularExpression.Options, matchingOptions: NSRegularExpression.MatchingOptions) {
        self.pattern = pattern
        self.expressionOptions = expressionOptions
        self.matchingOptions = matchingOptions
        updateRegex()
    }

    init(pattern: String) {
        self.pattern = pattern
        expressionOptions = NSRegularExpression.Options(rawValue: 0)
        matchingOptions = NSRegularExpression.MatchingOptions(rawValue: 0)
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
    func matchRegex(_ pattern: Regex) -> Bool {
        let range: NSRange = NSMakeRange(0, self.length)
        if pattern.regex != nil {
            let matches: [AnyObject] = pattern.regex!.matches(in: self, options: pattern.matchingOptions, range: range)
            return matches.count > 0
        }
        return false
    }

    func match(_ patternString: String) -> Bool {
        return self.matchRegex(Regex(pattern: patternString))
    }

    func replaceRegex(_ pattern: Regex, template: String) -> String {
        if self.matchRegex(pattern) {
            let range: NSRange = NSMakeRange(0, self.length)
            if pattern.regex != nil {
                return pattern.regex!.stringByReplacingMatches(in: self, options: pattern.matchingOptions, range: range, withTemplate: template)
            }
        }
        return self
    }

    func replace(_ pattern: String, template: String) -> String {
        return self.replaceRegex(Regex(pattern: pattern), template: template)
    }
}
/*
//e.g. replaces symbols +, -, space, ( & ) from phone numbers
"+91-999-929-5395".replace("[-\\s\\(\\)]", template: "")

*/
