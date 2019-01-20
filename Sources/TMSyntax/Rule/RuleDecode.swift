extension Rule {
    public static func decode(from decoder: Decoder) throws -> Rule {
        let loc = decoder.sourceLocation!
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
                         beginPosition: nil,
                         end: end,
                         endCaptures: endCaptures,
                         endPosition: nil,
                         patterns: patterns,
                         repository: repository,
                         scopeName: scopeName)
    }
}
