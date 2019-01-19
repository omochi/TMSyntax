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
            return "match rule (\(rule.pattern))\(rule.locationForDescription)"
        case .beginRule(let rule, let cond):
            return "begin rule (\(cond.begin))\(rule.locationForDescription)"
        case .endRule(let rule, let cond):
            return "end rule (\(cond.end))\(rule.locationForDescription)"
        }
    }
}

