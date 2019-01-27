extension Rule {
    public enum CodingKeys : String, CodingKey {
        case include
        case match
        case name
        case patterns
        case repository
        case begin
        case beginCaptures
        case end
        case endCaptures
        case captures
        case contentName
        case applyEndPatternLast
    }
    
    public static func decode(from decoder: Decoder) throws -> Rule {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        if let target = try c.decodeIfPresent(IncludeTarget.self, forKey: .include) {
            return IncludeRule(sourceLocation: decoder.sourceLocation,
                               target: target)
        }
        
        let scopeName = try c.decodeIfPresent(ScopeName.self, forKey: .name)
        
        if let matchPattern = try c.decodeIfPresent(RegexPattern.self, forKey: .match) {           
            let captures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .captures)
            
            return MatchRule(sourceLocation: decoder.sourceLocation,
                             pattern: matchPattern,
                             scopeName: scopeName,
                             captures: captures)
        }
        
        let patterns = try c.decodeIfPresent([Rule].self, forKey: .patterns) ?? []
        let repository = try c.decodeIfPresent(RuleRepository.self, forKey: .repository)
        
        let begin = try c.decodeIfPresent(RegexPattern.self, forKey: .begin)
        var beginCaptures: CaptureAttributes? = nil
        var end: RegexPattern? = nil
        var endCaptures: CaptureAttributes? = nil
        let contentName: ScopeName? = try c.decodeIfPresent(ScopeName.self, forKey: .contentName)
        let applyEndPatternLast: Bool = try c.decodeIfPresent(Bool.self, forKey: .applyEndPatternLast) ?? false
        
        if let _ = begin {
            beginCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .beginCaptures)
            
            end = try c.decode(RegexPattern.self, forKey: .end)
            endCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .endCaptures)
            
            if let captures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .captures) {
                beginCaptures = captures
                endCaptures = captures
            }
        }
        
        return ScopeRule(sourceLocation: decoder.sourceLocation,
                         begin: begin,
                         beginCaptures: beginCaptures,
                         end: end,
                         endCaptures: endCaptures,
                         contentName: contentName,
                         applyEndPatternLast: applyEndPatternLast,
                         patterns: patterns,
                         repository: repository,
                         scopeName: scopeName)
    }
}
