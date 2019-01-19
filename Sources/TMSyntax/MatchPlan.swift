import Foundation

public enum MatchPlan : CustomStringConvertible {
    case matchRule(MatchRule)
    case beginRule(ScopeRule, BeginEndCondition)
    case endRule(ScopeRule, BeginEndCondition)
    
    public var regexPattern: RegexPattern {
        switch self {
        case .matchRule(let rule):
            return rule.pattern
        case .beginRule(_, let cond):
            return cond.begin
        case .endRule(_, let cond):
            return cond.end
        }
    }
    
    public var description: String {
        switch self {
        case .matchRule(let rule):
            return "test: \(rule)"
        case .beginRule(let rule, _):
            return "begin test: \(rule)"
        case .endRule(let rule, _):
            return "end test: \(rule)"
        }
    }
}

