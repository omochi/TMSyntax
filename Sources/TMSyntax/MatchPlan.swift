import Foundation

public enum MatchPlan : CustomStringConvertible {
    case matchRule(MatchRule)
    case beginRule(ScopeRule, BeginEndCondition)
    
    public var regexPattern: String {
        switch self {
        case .matchRule(let rule):
            return rule.match
        case .beginRule(_, let cond):
            return cond.begin
        }
    }
    
    public var description: String {
        switch self {
        case .matchRule(let rule):
            return "match rule \(rule.match.debugDescription)\(rule.locationForDescription)"
        case .beginRule(let rule, let cond):
            return "begin rule \(cond.begin.debugDescription)\(rule.locationForDescription)"
        }
    }
    
    public func compile() throws -> Regex {
        switch self {
        case .matchRule(let rule):
            return try rule.matchRegex()
        case .beginRule(let rule, let cond):
            return try cond.beginRegex(rule: rule)
        }
    }
}

