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
        
        if let begin = try c.decodeIfPresent(RegexPattern.self, forKey: .begin) {
            var beginCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .beginCaptures)
            
            let end = try c.decode(RegexPattern.self, forKey: .end)
            var endCaptures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .endCaptures)
            
            if let captures = try c.decodeIfPresent(CaptureAttributes.self, forKey: .captures) {
                beginCaptures = captures
                endCaptures = captures
            }
            
            let cond = BeginEndCondition(begin: begin,
                                         beginCaptures: beginCaptures,
                                         end: end,
                                         endCaptures: endCaptures)
            
            return ScopeRule(sourceLocation: decoder.sourceLocation,
                             condition: .beginEnd(cond),
                             patterns: patterns,
                             repository: repository,
                             scopeName: scopeName)
        }
        
        return ScopeRule(sourceLocation: decoder.sourceLocation,
                         condition: .none,
                         patterns: patterns,
                         repository: repository,
                         scopeName: nil)
    }
}
